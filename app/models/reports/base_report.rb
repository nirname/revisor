require 'csv'

class Reports::BaseReport
  attr_reader :params

  # delegate :headers, :row, to: :result

  # Вместо ID
  def self.code
    name.demodulize.underscore
  end

  def code
    self.class.code
  end

  def title
    I18n.t("reports.#{code}")
  end

  # Для link_to report
  def to_s
    code
  end

  # Для render report
  def to_partial_path
    code.underscore.pluralize + '/report'
  end

  def initialize(params = {})
    @params = params
  end

  def query
    raise 'Пустой запросъ'
  end

  def results
    @results = Result.where(shard: shards, code: code)
    if params.present?
      @results.where('params = ?', params.to_json)
    else
      @results.where('params IS NULL')
    end
  end

  def result_on_shard(shard)
    @results_on_shards ||= {}
    @results_on_shards[shard] ||= results.where(shard: shard).first_or_create(shard: shard, code: code, params: (params.present? ? params : nil))
  end

  def on_shards?
    false
  end

  def shards
    if Rails.env == 'production' && on_shards?
    # if on_shards?
      %w(shard_0 shard_1)
    else
      %w(main)
    end
    # %w(shard_0 shard_1)
  end

  def make
    shards.map do |shard|
      next if SETTINGS[shard].blank?

      database = SETTINGS[shard]['database']
      host     = SETTINGS[shard]['host']
      port     = SETTINGS[shard]['port']
      user     = SETTINGS[shard]['username']

      return 'Не указаны параметры подключения к базе' if database.blank? or host.blank? or port.blank? or user.blank?

      command = %(psql -h #{host} -p #{port} -d #{ database } -U #{user} -c "" -v ON_ERROR_STOP=1 2>&1)
      output = `#{command}`
      raise output if $? != 0

      prepared_query = "COPY (#{query.gsub('"', '\"')}) TO STDOUT WITH CSV DELIMITER ',' HEADER"

      command = %(psql -h #{host} -p #{port} -d #{ database } -U #{user} -c "#{prepared_query}" -v ON_ERROR_STOP=1 2>&1)
      output = `#{command}`

      if $? == 0
        self.result_on_shard(shard).data = output
        self.result_on_shard(shard).save
      else
        raise output
      end
      "shard #{shard}: ok"
    end.join('; ')
  end

  def draw
    shards.map do |shard|
      data_file = Tempfile.new
      plot_file = Tempfile.new

      begin
        result = self.result_on_shard(shard)
        data_content = result.data
        data_file.write(data_content)
        data_file.rewind

        plot_content = "
          set title \"#{title}\"
          set datafile separator ','
          set terminal svg
          #{plot}
        "
        plot_file.write(plot_content)
        plot_file.rewind

        vars = {
          data: data_file.path,
          title: title
        }
        prepared_vars = vars.flat_map{ |k, v| "#{k}='#{v}'"}.join(';')

        command = %(gnuplot -e "#{prepared_vars}" #{plot_file.path} > #{Rails.root}/public/plots/#{result.id})
        output = `#{command}`
      ensure
        data_file.close
        data_file.unlink

        plot_file.close
        plot_file.unklink
      end
    end
  end
end
