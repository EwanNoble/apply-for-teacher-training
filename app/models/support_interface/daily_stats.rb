module SupportInterface
  class DailyStats
    attr_reader :date

    def initialize(date)
      @date = date.to_date
    end

    def applications_begun
      ApplicationForm.where(created_at: @date).count
    end

    def apply_again_applications_begun
      ApplicationForm.where(created_at: @date, phase: 'apply_2').count
    end

    def applications_submitted
      ApplicationForm.where(submitted_at: @date).count
    end

    def offers_made
      ApplicationChoice
        .includes(:application_form)
        .where(offered_at: @date).map(&:application_form)
    end

    def offers_made_provider_stats
      ApplicationChoice
        .includes(:application_form)
        .where(offered_at: @date).map(&:provider).tally
    end

    def candidates_recruited
      # candidates cannot have two accepted choices at the
      # same time, so recruitment is guaranteed to happen
      # at most once per application form
      ApplicationChoice
        .includes(:application_form)
        .where(recruited_at: @date).map(&:application_form)
    end

    def candidates_recruited_provider_stats
      ApplicationChoice
        .includes(:application_form)
        .where(recruited_at: @date).map(&:provider).tally
    end

    def candidates_rejected
      ApplicationChoice
        .includes(:application_form)
        .where(rejected_at: @date).map(&:application_form).uniq
    end

    def candidates_rejected_provider_stats
      ApplicationChoice
        .includes(:application_form)
        .where(rejected_at: @date).map(&:provider).tally
    end

    def rbd_provider_stats
      ApplicationChoice
        .includes(:application_form)
        .where(rejected_at: @date, rejected_by_default: true).map(&:provider).tally
    end

    def candidates_rejected_by_default
      ApplicationChoice
        .includes(:application_form)
        .where(rejected_at: @date, rejected_by_default: true).map(&:application_form)
    end
  end
end
