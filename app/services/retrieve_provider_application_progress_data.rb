class RetrieveProviderApplicationProgressData
  attr_reader :provider

  def initialize(provider:)
    @provider = provider
  end

  def exec
    Course.joins(:application_choices).merge(provider_application_choices).
           group('courses.id', 'application_choices.status').
           select("count('application_choices.status') as count", 'application_choices.status as status', "courses.id")
  end

  private

  def provider_application_choices
    ApplicationChoice.joins(:course).
      where(status: %i[awaiting_provider_decision interviewing offer pending_conditions recruited]).
      where(course: { provider: provider }).
      or(ApplicationChoice.joins(:course).where(course: { accredited_provider: provider })).
      where(course: { recruitment_cycle_year: RecruitmentCycle.current_year })
  end
end
