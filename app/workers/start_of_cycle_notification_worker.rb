class StartOfCycleNotificationWorker
  include Sidekiq::Worker

  def perform(service)
    return unless CycleTimetable.service_opens_today?(service, year: RecruitmentCycle.current_year)
    return unless hours_remaining.positive?

    @service = service

    providers_scope.limit(fetch_limit).each do |provider|
      provider.provider_users.each do |provider_user|
        unless ChaserSent.exists?(chased: provider_user, chaser_type: service_open_email)
          ProviderMailer.send(service_open_email, provider_user).deliver_later
          ChaserSent.create!(chased: provider_user, chaser_type: service_open_email)
        end

        next if service == 'apply'
        next unless relationships_pending_for(provider_user).any?
        next if ChaserSent.exists?(chased: provider_user, chaser_type: setup_missing_org_permissions_email)

        ProviderMailer.send(setup_missing_org_permissions_email, provider_user, relationships_to_set_up(provider_user)).deliver_later
        ChaserSent.create!(chased: provider_user, chaser_type: setup_missing_org_permissions_email)
      end

      ChaserSent.create!(chased: provider, chaser_type: provider_was_chased)
    end
  end

private

  attr_reader :service

  def fetch_limit
    (provider_count / hours_remaining).ceil
  end

  def provider_count
    providers_scope.count
  end

  def hours_remaining
    notify_until.hour - Time.zone.now.hour
  end

  def notify_until
    Time.zone.now.change(hour: 17)
  end

  def relationships_to_set_up(provider_user)
    relationships_pending = relationships_pending_for(provider_user)
    training_providers = relationships_pending.map(&:training_provider) & provider_user.providers

    relationships = relationships_pending.each_with_object({}) do |rel, hash|
      if training_providers.include?(rel.training_provider)
        hash[rel.training_provider.name] ||= []
        hash[rel.training_provider.name] << rel.ratifying_provider.name
      else
        hash[rel.ratifying_provider.name] ||= []
        hash[rel.ratifying_provider.name] << rel.training_provider.name
      end
    end
    relationships.sort_by { |k, v| [k, v.sort!] }.to_h
  end

  def relationships_pending_for(provider_user)
    ProviderSetup.new(provider_user: provider_user).relationships_pending
  end

  def providers_scope
    Provider
      .joins('INNER JOIN provider_users_providers ON providers.id = provider_users_providers.provider_id')
      .joins('INNER JOIN provider_users ON provider_users.id = provider_users_providers.provider_user_id')
      .where.not(Arel.sql(providers_whose_users_have_been_chased))
      .order('providers.name')
      .distinct
  end

  def providers_whose_users_have_been_chased
    <<-SQL.squish
      EXISTS(
        SELECT 1
        FROM chasers_sent
        WHERE chased_type = 'Provider'
        AND chased_id = providers.id
        AND chaser_type = '#{provider_was_chased}'
      )
    SQL
  end

  def service_open_email
    "#{service}_service_is_now_open"
  end

  def setup_missing_org_permissions_email
    'set_up_organisation_permissions'
  end

  def provider_was_chased
    "#{service}_service_open_organisation_notification"
  end
end
