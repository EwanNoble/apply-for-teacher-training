module ProviderInterface
  class DeclineOrWithdrawApplication
    def initialize(actor:, application_choice:)
      @actor = actor
      @application_choice = application_choice
    end

    def save!
      return false unless declining? || withdrawing?

      auth.assert_can_make_decisions!(application_choice: @application_choice, course_option: @application_choice.current_course_option)
      if declining?
        decline!
      elsif withdrawing?
        withdraw!
        cancel_upcoming_interviews!
      end

      SendCandidateWithdrawnOnRequestEmail.new(application_choice: application_choice).call

      true
    end

  private

    attr_reader :application_choice

    def declining?
      application_choice.offer?
    end

    def decline!
      ActiveRecord::Base.transaction do
        ApplicationStateChange.new(@application_choice).decline!
        @application_choice.update!(
          declined_at: Time.zone.now,
          audit_comment: I18n.t('transient_application_states.withdrawn_at_candidates_request.declined.audit_comment'),
        )
      end
    end

    def withdrawing?
      ApplicationStateChange.new(application_choice).can_withdraw?
    end

    def withdraw!
      ActiveRecord::Base.transaction do
        ApplicationStateChange.new(@application_choice).withdraw!
        @application_choice.update!(
          withdrawn_at: Time.zone.now,
          audit_comment: I18n.t('transient_application_states.withdrawn_at_candidates_request.withdrawn.audit_comment'),
        )
        SetDeclineByDefault.new(application_form: @application_choice.application_form).call
      end
    end

    def cancel_upcoming_interviews!
      CancelUpcomingInterviews.new(
        actor: @actor,
        application_choice: @application_choice,
        cancellation_reason: I18n.t('interview_cancellation.reason.application_withdrawn'),
      ).call!
    end

    def auth
      @auth ||= ProviderAuthorisation.new(actor: @actor)
    end

    def transition
      declining? ? :declined : :withdrawn
    end
  end
end
