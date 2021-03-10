class ProviderUserNotificationPreferences < ActiveRecord::Base
  belongs_to :provider_user

  self.table_name = :provider_user_notifications

  NOTIFICATION_PREFERENCES = %i[
    application_received
    application_withdrawn
    application_rejected_by_default
    offer_accepted
    offer_declined
  ].freeze

  def self.notification_preference_exists?(notification_name)
    NOTIFICATION_PREFERENCES.include? notification_name
  end
end
