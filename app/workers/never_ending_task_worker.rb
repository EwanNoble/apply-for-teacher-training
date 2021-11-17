class NeverEndingTaskWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0, queue: :low_priority

  def perform(interval)
    Rails.logger.warn "NeverEndingTask interval: #{interval} starts"
    count = 0
    while(true) do
      sleep interval
      count += 1
      Rails.logger.warn "interval: #{interval} count: #{count}"
    end
  end
end
