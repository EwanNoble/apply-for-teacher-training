module SupportInterface
  class FraudAuditingMatchesTableComponent < ViewComponent::Base
    include ViewHelper

    attr_reader :matches

    def initialize(matches:)
      @matches = matches
    end

    def table_rows
      matches.map do |match|
        {
          first_names: match.candidates.map { |candidate| candidate.application_forms.first.first_name },
          last_name: match.last_name,
          fraudulent?: marked_as_fraudulent?(match),
          candidate_last_contacted_at: match.candidate_last_contacted_at&.to_s(:govuk_date_and_time),
          email_addresses: match.candidates.map { |candidate| candidate },
          submitted_at: match.candidates.map { |candidate| submitted?(candidate) },
        }
      end
    end

  private

    def submitted?(candidate)
      if candidate.current_application.submitted_at?
        'Yes'
      else
        'No'
      end
    end

    def marked_as_fraudulent?(match)
      if match.fraudulent?
        'Yes'
      else
        'No'
      end
    end
  end
end
