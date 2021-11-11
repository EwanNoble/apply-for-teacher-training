module MonthlyStatistics
  class ByProviderArea < MonthlyStatistics::Base
    def table_data
      {
        rows: rows,
        column_totals: column_totals_for(rows),
      }
    end

  private

    def rows
      @rows ||= formatted_group_query.map do |provider_area, statuses|
        {
          'Area' => provider_area,
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
      _provider_area, *statuses = rows.first.keys

      statuses.map do |column_name|
        column_total = rows.inject(0) { |total, hash| total + hash[column_name] }
        column_total
      end
    end

    def formatted_group_query
      counts = {
        'East' => {},
        'East Midlands' => {},
        'London' => {},
        'North East' => {},
        'North West' => {},
        'South East' => {},
        'South West' => {},
        'West Midlands' => {},
        'Yorkshire and The Humber' => {},
      }

      group_query_excluding_deferred_offers.map do |item|
        region_code, status = item[0]
        count = item[1]
        counts[region_code_lookup(region_code)]&.merge!({ status => count })
      end

      group_query_for_deferred_offers.map do |item|
        region_code, status = item[0]
        count = item[1]
        counts[region_code_lookup(region_code)]&.merge!({ status => count })
      end

      counts
    end

    def region_code_lookup(region_code)
      {
        'eastern' => 'East',
        'east_midlands' => 'East Midlands',
        'london' => 'London',
        'north_east' => 'North East',
        'north_west' => 'North West',
        'south_east' => 'South East',
        'south_west' => 'South West',
        'west_midlands' => 'West Midlands',
        'yorkshire_and_the_humber' => 'Yorkshire and The Humber',
      }[region_code]
    end

    def group_query_for_deferred_offers
      group_query(recruitment_cycle_year: RecruitmentCycle.previous_year)
        .where(status: :offer_deferred)
        .group('providers.region_code', 'status_before_deferral')
        .count
    end

    def group_query_excluding_deferred_offers
      group_query(recruitment_cycle_year: RecruitmentCycle.current_year)
        .where.not(status: :offer_deferred)
        .group('providers.region_code', 'status')
        .count
    end

    def group_query(recruitment_cycle_year:)
      ApplicationChoice
        .joins(course_option: { site: :provider })
        .where(current_recruitment_cycle_year: recruitment_cycle_year)
    end
  end
end