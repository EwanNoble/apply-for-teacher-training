module CandidateInterface
  class CarryOverInterstitialComponent < ViewComponent::Base
    include ViewHelper

    def initialize(application_form:)
      @application_form = application_form
    end

    def application_form_academic_cycle
      RecruitmentCycle.cycle_name(application_form_recruitment_cycle_year + 1)
    end

    def next_academic_cycle
      RecruitmentCycle.cycle_name(next_recruitment_cycle_year + 1)
    end

  private

    def application_form_recruitment_cycle_year
      @application_form.recruitment_cycle_year
    end

    def next_recruitment_cycle_year
      application_form_recruitment_cycle_year + 1
    end
  end
end
