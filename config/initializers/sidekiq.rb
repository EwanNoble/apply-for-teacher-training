require 'workers/audit_trail_attribution_middleware'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Workers::AuditTrailAttributionMiddleware
  end

  Yabeda::Prometheus::Exporter.start_metrics_server!
end

require 'sidekiq/web'
require 'sidekiq/cron/web'

schedule_file = "config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Rails.application.config.after_initialize do
    Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file)
  end
end
