module SupportInterface
  class DailyStatsController < SupportInterface::SupportInterfaceController
    def show
      @stats = SupportInterface::DailyStats.new(Time.zone.now)
    end
  end
end

