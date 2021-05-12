class WorkHistoryAndUnpaidExperienceComponent < WorkHistoryComponent
  def initialize(application_form:)
    @application_form = application_form
    @work_history_with_breaks ||= WorkHistoryWithBreaks.new(application_form, include_unpaid_experience: true)
  end

  def subtitle
    if has_work_history? && !has_unpaid_experience?
      'Details of work history'
    elsif !has_work_history? && has_unpaid_experience?
      'Details of unpaid experience'
    end
  end

private

  def rows
    {
      'Do you have any work history' => work_history_text,
      'Do you have any unpaid experience' => unpaid_experience_text,
    }
  end

  def work_history_text
    if !has_work_history? && full_time_education?
      ' No, I have always been in full time education'
    else
      has_work_history? ? 'Yes' : 'No'
    end
  end

  def unpaid_experience_text
    has_unpaid_experience? ? 'Yes' : 'No'
  end

  delegate :full_time_education?, to: :application_form

  def has_work_history?
    work_history_with_breaks.work_history.any?
  end

  def has_unpaid_experience?
    work_history_with_breaks.unpaid_work.any?
  end
end
