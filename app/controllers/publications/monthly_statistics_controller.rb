module Publications
  class MonthlyStatisticsController < ApplicationController
    before_action :redirect_unless_published

    def show
      @presenter = if params[:month].present?
                     Publications::MonthlyStatisticsPresenter.new(
                       MonthlyStatisticsTimetable.report_for(params[:month]),
                     )
                   else
                     Publications::MonthlyStatisticsPresenter.new(
                       MonthlyStatisticsTimetable.report_for_current_period,
                     )
                   end
    end

    def redirect_unless_published
      redirect_to root_path unless FeatureFlag.active?(:publish_monthly_statistics)
    end
  end
end
