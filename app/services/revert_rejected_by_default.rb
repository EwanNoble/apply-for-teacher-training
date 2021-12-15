class RecalculateDates
  include Sidekiq::Worker

  def perform(*)
    Audited.audit_class.as_user('RecalculateDates worker') do
      ApplicationChoice
        .where(id: ids, rejected_by_default: true)
        .includes(:application_form)
        .find_each do |application_choice|
          application_choice.update!(
            reject_by_default_at: Time.zone.local(2022, 1, 17, 23, 59),
            status: :awaiting_provider_decision,
            rejected_by_default: false,
            rejected_at: nil
          )
        end

      application_choice.self_and_siblings.update_all(declined_by_default_at: nil, decline_by_default_days: nil)

    end
  end
end
