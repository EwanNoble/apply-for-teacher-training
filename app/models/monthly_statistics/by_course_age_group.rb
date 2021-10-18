module MonthlyStatistics
  class ByCourseAgeGroup < MonthlyStatistics::Base
    def table_data
      {
        rows: rows,
        column_totals: column_totals_for(rows),
      }
    end

  private

    def rows
      @rows ||= formatted_group_query.map do |age_group, statuses|
        {
          'Age group' => age_group,
          'Recruited' => recruited_count(statuses),
          'Conditions pending' => pending_count(statuses),
          'Received an offer' => offer_count(statuses),
          'Awaiting provider decisions' => awaiting_decision_count(statuses),
          'Unsuccessful' => unsuccessful_count(statuses),
          'Total' => statuses_count(statuses),
        }
      end
    end

    def column_totals_for(rows)
      _age_group, *statuses = rows.first.keys

      statuses.map do |column_name|
        column_total = rows.inject(0) { |total, hash| total + hash[column_name] }
        column_total
      end
    end

    def formatted_group_query
      counts = {
        'Primary' => {},
        'Secondary' => {},
        'Further education' => {},
      }

      group_query.map do |item|
        level, status = item[0]
        count = item[1]
        counts[level].merge!({ status => count })
      end

      counts
    end

    def group_query
      ApplicationChoice
        .joins(:course)
        .where(current_recruitment_cycle_year: RecruitmentCycle.current_year)
        .group('courses.level', 'status')
        .count
    end
  end
end
