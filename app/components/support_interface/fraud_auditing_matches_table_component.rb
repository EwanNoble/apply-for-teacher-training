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
          match: match,
          first_names: match.candidates.map { |candidate| candidate.application_forms.first.first_name },
          last_name: match.last_name,
          fraudulent?: marked_as_fraudulent?(match),
          candidate_last_contacted_at: match.candidate_last_contacted_at&.to_s(:govuk_date_and_time),
          email_addresses: match.candidates,
          submitted_at: match.candidates.map { |candidate| submitted?(candidate) },
          blocked: match.id,
        }
      end
    end

    def candidate_blocked?(fraud_id)
      FraudMatch.find(fraud_id).blocked
    end

  private

    def submitted?(candidate)
      candidate.current_application.submitted? ? 'Yes' : 'No'
    end

    def marked_as_fraudulent?(match)
      match.fraudulent? ? 'Yes' : 'No'
    end
  end
end
