class ReportsController < ApplicationController
  def index
    @reports = Report.order(:name)
  end

  def new
    @report = Report.new
  end

  def edit
    @report = Report.find(params[:id])
  end

  def copy
    @report = Report.new(Report.find(params[:id]).attributes.except(:id))
    render 'new'
  end

  def email
    @report = Report.find(params[:id])
    if ReportMailer.report_mail(@report).deliver_now
      redirect_to @report, message: 'Депеша отправлена'
    else
      redirect_to @report, error: 'Не удалось отправить депешу'
    end
  end

  def export
    @report = Report.find(params[:id])
    redirect_to(reports_path, notice: 'Нет результата') and return unless @report.data.present?

    respond_to do |format|
      format.xlsx { render xlsx: 'export', locals: { report: @report } }
    end
  end

  def result
    @report = Report.find(params[:id])
    redirect_to(reports_path, notice: 'Нет результата') and return unless @report.data.present?

    respond_to do |format|
      format.zip do
        zip_name = "report-#{@report.id}-result.zip"
        dir_name = "report-#{@report.id}-result"
        tmp_path = Rails.root.join('tmp', 'reports')

        `mkdir -p #{tmp_path}/#{dir_name}`

        redirect_to :report, notice: "#{$?}" and return unless $? == 0

        File.open(File.join(tmp_path, dir_name, 'data.csv'), 'w') { |file| file.write(@report.data) }
        `cp #{Rails.root}/public/plots/#{ @report.image_name } #{tmp_path}/#{dir_name}` if @report.plot.present?

        `cd #{tmp_path} && zip -r #{zip_name} #{dir_name}`

        if $? == 0
          zip_data = File.read("#{tmp_path}/#{zip_name}")
          send_data(zip_data, :type => 'application/zip', :filename => zip_name)
        else
          redirect_to :reports, alert: "#{$?}"
        end

        `rm -rf #{tmp_path}/#{dir_name} #{tmp_path}/#{zip_name}`
      end
    end
  end

  def source
    @report = Report.find(params[:id])

    respond_to do |format|
      format.zip do
        zip_name = "report-#{@report.id}-source.zip"
        dir_name = "report-#{@report.id}-source"
        tmp_path = Rails.root.join('tmp', 'reports')

        `mkdir -p #{tmp_path}/#{dir_name}`

        redirect_to :report, notice: "#{$?}" and return unless $? == 0

        File.open(File.join(tmp_path, dir_name, 'query.sql'), 'w') { |file| file.write(@report.query) }
        File.open(File.join(tmp_path, dir_name, 'plot.gp'), 'w') { |file| file.write(@report.plot) }

        `cd #{tmp_path} && zip -r #{zip_name} #{dir_name}`

        if $? == 0
          zip_data = File.read("#{tmp_path}/#{zip_name}")
          send_data(zip_data, :type => 'application/zip', :filename => zip_name)
        else
          redirect_to :reports, notice: "#{$?}"
        end

        `rm -rf #{tmp_path}/#{dir_name} #{tmp_path}/#{zip_name}`
      end
      format.json do
        render json: @report
      end
    end
  end

  def create
    @report = Report.new(report_params)
    notices = []
    alerts = []
    if @report.save
      notices << "Отчет '#{ @report.name }' создан"
      if params[:update_query]
        notices << @report.make_data
        notices << @report.make_image
      elsif params[:update_plot]
        notices << @report.make_image
      end
      redirect_to edit_report_path(@report), notice: notices
    else
      alerts = @report.errors.messages
      flash.now[:alert] = alerts
      render 'new'
    end
  end

  def update
    @report = Report.find(params[:id])
    notices = []
    alerts = []
    if @report.update(report_params)
      notices << ["Отчет '#{ @report.name }' изменен"]
      if params[:update_query]
        notices << @report.make_data
        notices << @report.make_image
      elsif params[:update_plot]
        notices << @report.make_image
      end
      redirect_to edit_report_path(@report), notice: notices
    else
      alerts = @report.errors.messages
      flash.now[:alert] = alerts
      render 'edit'
    end
  end

  def show
    @report = Report.find(params[:id])
  end

  def make
    # TODO delayed job
    @report = Report.find(params[:id])
    message = @report.make
    redirect_to @report, notice: message
  end

  # def make_data
  #   @report = Report.find(params[:id])
  #   message = @report.make_data
  #   redirect_to((request.referer || @report), notice: message)
  # end

  # def make_image
  #   @report = Report.find(params[:id])
  #   message = @report.make_image
  #   redirect_to((request.referer || @report), notice: message)
  # end

  def destroy
    @report = Report.find(params[:id])
    @report.destroy
    redirect_to reports_path, notice: "Отчет '#{ @report.name }' удален"
  end

  private

  def report_params
    params.require(:report).permit(:name, :query, :plot)
  end
end
