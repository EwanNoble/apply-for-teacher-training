class SendEocDeadlineReminderEmailToCandidatesWorker
  include Sidekiq::Worker

  def perform
    return unless CycleTimetable.need_to_send_deadline_reminder?

    applications_to_send_reminders_to.find_each(batch_size: 100) do |application|
      SendEocDeadlineReminderEmailToCandidate.call(application_form: application)
    end
  end

  def applications_to_send_reminders_to
    if CycleTimetable.need_to_send_deadline_reminder? == :apply_1
      ApplicationForm
      .joins(:candidate)
      .where(submitted_at: nil, phase: 'apply_1', recruitment_cycle_year: RecruitmentCycle.current_year)
      .where.not(candidate: { unsubscribed_from_emails: true })
    elsif CycleTimetable.need_to_send_deadline_reminder? == :apply_2
      ApplicationForm
      .joins(:candidate)
      .where(submitted_at: nil, phase: 'apply_2', recruitment_cycle_year: RecruitmentCycle.current_year)
      .where.not(candidate: { unsubscribed_from_emails: true })
    end
  end
end
