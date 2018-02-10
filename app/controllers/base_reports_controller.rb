class BaseReportsController < ApplicationController
  def show
    render locals: { report: report }
  end

  def make
    message = report.make
    redirect_to :back, notice: message
  end

  def export
    respond_to do |format|
      format.xlsx { render xlsx: 'export', filename: report.title + ".xlsx", locals: { report: report } }
    end
  end

  def email
    if ReportMailer.base_report_mail(@base_report, current_user.email).deliver_now
      redirect_to :back, message: 'Депеша отправлена'
    else
      redirect_to :back, error: 'Не удалось отправить депешу'
    end
  end

  private

  def report
    @report ||= Reports.find(params[:id]).new
  end
end
