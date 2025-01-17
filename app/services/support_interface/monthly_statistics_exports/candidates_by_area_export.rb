module SupportInterface
  module MonthlyStatisticsExports
    class CandidatesByAreaExport
      include MonthlyStatisticsExportHelper

      def data_for_export(*)
        data = Publications::MonthlyStatistics::ByArea.new.table_data
        merge_rows_and_totals(data)
      end
    end
  end
end
