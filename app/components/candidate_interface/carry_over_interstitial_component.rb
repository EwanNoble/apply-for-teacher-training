module CandidateInterface
  class CarryOverInterstitialComponent < ViewComponent::Base
    include ViewHelper

    def initialize(application_form:)
      @application_form = application_form
    end

    def application_form_cycle_name
      RecruitmentCycle.cycle_name(application_form_recruitment_cycle_year)
    end

    def next_cycle_name
      RecruitmentCycle.cycle_name(next_recruitment_cycle_year)
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
