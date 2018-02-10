class ReportMailer < MandrillMailer::MessageMailer
  default from: 'revisor@example.com'

  def report_mail(report, ac = nil)
    recipients = %w(user@example.com)
    ac ||= ActionController::Base.new()

    mandrill_mail subject: report.name,
                  to: recipients,
                  text: report.name,
                  attachments: [
                    content: ac.render_to_string('reports/export', locals: { report: report }),
                    name: report.name + '.xlsx',
                    type: 'text/xslx'
                  ]
  end

  def base_report_mail(report, recipients)
    ac = ActionController::Base.new()
    mandrill_mail subject: report.title,
                  to: recipients,
                  text: report.title,
                  attachments: [
                    content: ac.render_to_string(partial: 'base_reports/export', locals: { report: report }),
                    name: report.title + '.xlsx',
                    type: 'text/xslx'
                  ]
  end
end
