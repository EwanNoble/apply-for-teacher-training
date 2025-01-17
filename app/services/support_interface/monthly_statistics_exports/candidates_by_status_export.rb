module SupportInterface
  module MonthlyStatisticsExports
    class CandidatesByStatusExport
      include MonthlyStatisticsExportHelper

      def data_for_export(*)
        data = Publications::MonthlyStatistics::ByStatus.new(by_candidate: true).table_data
        merge_rows_and_totals(data)
      end
    end
  end
end
