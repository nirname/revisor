class DashboardController < ApplicationController
  def index
    @dashboard_reports = Reports.all.sort_by{ |report| report.code }.map{ |report| report.new }
  end
end
