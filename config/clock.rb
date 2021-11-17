require './config/boot'
require './config/environment'

require 'clockwork'

class Clock
  include Clockwork

  error_handler { |error| Sentry.capture_exception(error) if defined? Sentry }
end
