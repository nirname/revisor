require 'csv'

class Report < ApplicationRecord
  validates :name, presence: true

  def formatted_data
    @formatted_data ||= CSV.parse(data)
  end

  def headers
    formatted_data[0]
  end

  def rows(limit = nil)
    _rows = formatted_data[1..-1]
    _rows = _rows.first(limit) if limit
    _rows
  end

  def image_name
    "#{id}.svg"
  end

  # Слеш в начале не убирать!
  def image_path
    "/plots/#{image_name}"
  end

  def make_data
    return 'Пустой запросъ' if query.blank?

    database = SETTINGS['main']['database']
    host     = SETTINGS['main']['host']
    port     = SETTINGS['main']['port']
    user     = SETTINGS['main']['user']

    return 'Не указаны параметры подключения к базе' if database.blank? or host.blank? or port.blank? or user.blank?

    command = %(psql -h #{host} -p #{port} -d #{ database } -U #{user} -c "" -v ON_ERROR_STOP=1 2>&1)
    output = `#{command}`
    return output if $? != 0

    prepared_query = "COPY (#{query.gsub('"', '\"')}) TO STDOUT WITH CSV DELIMITER ',' HEADER"

    # -t -A -F','
    command = %(psql -h #{host} -p #{port} -d #{ database } -U #{user} -c "#{prepared_query}" -v ON_ERROR_STOP=1 2>&1)
    output = `#{command}`

    # TODO сохранять ли результат с ошибкой?
    return output if $? != 0

    self.data = output
    save

    'Данные получены'
  end

  def make_image
    return 'Нет данных' if data.blank?
    return 'Без графика' if plot.blank?

    plot_file = Tempfile.new
    data_file = Tempfile.new

    data_file.write(data)
    data_file.rewind

    prepared_plot = "
      set title \"#{name}\"
      #{plot}
    "
    plot_file.write(prepared_plot)
    plot_file.rewind

    # TODO создавать папку, вынести в переменную
    vars = {
      data: data_file.path,
      name: name
    }
    prepared_vars = vars.flat_map{ |k, v| "#{k}='#{v}'"}.join(';')

    # TODO проверить image_path
    # rm -f #{image_path} &&
    command = %(gnuplot -e "#{prepared_vars}" #{plot_file.path} > #{Rails.root}/public/plots/#{image_name})
    output = `#{command}`

    # TODO сохранять временные файлы, и выводить команду для сборки отчета
    return command if $? != 0

    plot_file.close
    plot_file.unlink

    data_file.close
    data_file.unlink

    'Графикъ построен'
  end

  def make
    make_data
    make_image
    'Отчетъ сформирован'
  end
end
