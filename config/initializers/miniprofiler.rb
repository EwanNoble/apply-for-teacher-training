Rails.application.config.to_prepare do
  ::Rack::MiniProfiler.profile_method(ProviderInterface::ReasonsForRejectionController, :update_initial_questions) { 'updating initial questions' }
end
