FactoryBot.define do
  factory :provider_permissions do
    provider
    provider_user

    trait :with_random_permissions do
      ProviderPermissions::VALID_PERMISSIONS.each { |permission| send(permission) { Faker::Boolean.boolean(true_ratio: 0.5) } }
    end
  end
end
