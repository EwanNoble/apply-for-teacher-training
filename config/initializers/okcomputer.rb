require 'teacher_training_public_api/sync_check'

class SimulatedFailureCheck < OkComputer::Check
  def check
    if FeatureFlag.active?('force_ok_computer_to_fail')
      mark_failure
      mark_message 'force_ok_computer_to_fail is on'
    else
      mark_message 'force_ok_computer_to_fail is off'
    end
  end
end

OkComputer.mount_at = 'integrations/monitoring'

OkComputer::Registry.register 'postgres', OkComputer::ActiveRecordCheck.new
OkComputer::Registry.register 'redis', OkComputer::RedisCheck.new(url: ENV['REDIS_URL'])
OkComputer::Registry.register 'simulated_failure', SimulatedFailureCheck.new
OkComputer::Registry.register 'version', OkComputer::AppVersionCheck.new

OkComputer.make_optional %w[version]
