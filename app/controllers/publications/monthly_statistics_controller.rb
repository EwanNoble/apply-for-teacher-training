module Publications
  class MonthlyStatisticsController < ApplicationController
    before_action :redirect_unless_published

    def show
      @presenter = Publications::MonthlyStatisticsPresenter.new(
        MonthlyStatisticsTimetable.current_report,
      )
      @monthly_statistics_report = MonthlyStatisticsTimetable.current_report
      @statistics = @monthly_statistics_report.statistics
      @report = calculate_download_size
      @academic_year_name = RecruitmentCycle.cycle_name(CycleTimetable.next_year)
      @current_cycle_name = RecruitmentCycle.verbose_cycle_name
    end

    def download
      return render_404 unless valid_date?

      export_type = params[:export_type]
      export_filename = "#{export_type}-#{params[:date]}.csv"
      raw_data = MonthlyStatisticsTimetable.current_report.statistics[export_type]
      header_row = raw_data['rows'].first.keys
      data = SafeCSV.generate(raw_data['rows'].map(&:values), header_row)
      send_data data, filename: export_filename, disposition: :attachment
    end

    def redirect_unless_published
      redirect_to root_path unless FeatureFlag.active?(:publish_monthly_statistics)
    end

    def valid_date?
      params[:date] == Time.zone.today.strftime('%Y-%m')
    end

    def calculate_download_size
      @monthly_statistics_report.statistics.map do |k, raw_data|
        header_row = raw_data['rows'].first.keys
        data = SafeCSV.generate(raw_data['rows'].map(&:values), header_row)
        [k, data.size]
      end
    end
  end
end
