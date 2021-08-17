require 'rails_helper'
RSpec.describe ProviderInterface::EditUserPermissionsWizard do
  describe '.from_model' do
    context 'initialising the wizard from a provider permissions object' do
      let(:store) { instance_double(WizardStateStores::RedisStore, read: {}) }
      let(:provider_permissions) { build_stubbed(:provider_permissions, :with_random_permissions) }

      it 'initializes a wizard from the interview model' do
        wizard = described_class.from_model(store, provider_permissions)

        expect(wizard.manage_users).to eq(provider_permissions.manage_users)
      end
    end

    context 'initialising a wizard from the store' do
      let(:store) { instance_double(WizardStateStores::RedisStore, read: { manage_users: true, make_decisions: false }.to_json) }
      let(:provider_permissions) { build_stubbed(:provider_permissions, manage_users: false, make_decisions: true) }

      it 'initializes a wizard from the stored data' do
        wizard = described_class.from_model(store, provider_permissions)

        expect(wizard.manage_users).to eq(true)
        expect(wizard.make_decisions).to eq(false)
      end
    end
  end
end
