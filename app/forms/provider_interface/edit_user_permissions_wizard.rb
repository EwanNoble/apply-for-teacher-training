module ProviderInterface
  class EditUserPermissionsWizard
    include ActiveModel::Model

    ProviderPermissions::VALID_PERMISSIONS.each { |permission| attr_accessor permission }

    def initialize(state_store, attrs = {})
      @state_store = state_store

      super(last_saved_state.deep_merge(attrs))
    end

    def self.from_model(store, provider_permissions)
      wizard = new(store)

      ProviderPermissions::VALID_PERMISSIONS.each do |permission|
        if wizard.send(permission).nil?
          wizard.send("#{permission}=", provider_permissions.send(permission))
        end
      end

      wizard
    end

    def save_state!
      @state_store.write(state)
    end

    def clear_state!
      @state_store.delete
    end

  private
    def last_saved_state
      saved_state = @state_store.read
      saved_state ? JSON.parse(saved_state) : {}
    end

    def state
      as_json(except: %w[state_store errors validation_context]).to_json
    end
  end
end
