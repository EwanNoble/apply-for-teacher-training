module Wizard::PathHistory
  extend ActiveSupport::Concern

  module Initializer
    def initialize(state_store, attrs = {})
      @state_store = state_store

      super(last_saved_state.deep_merge(attrs))
      @path_history ||= [:referer]
      update_path_history(attrs)
    end
  end

  def self.included(klass)
    klass.send :prepend, Initializer
  end

  def previous_step
    wizard_path_history.previous_step
  rescue WizardPathHistory::NoSuchStepError
    :referer
  end

private

  def update_path_history(attrs)
    @wizard_path_history = WizardPathHistory.new(@path_history,
                                                 step: attrs[:current_step].presence,
                                                 action: attrs[:action].presence)
    @wizard_path_history.update
    @path_history = @wizard_path_history.path_history
  end
end
