require 'logger'
require 'newrelic_rpm'

module Loggable
  def logger
    Loggable.shared_logger
  end

  def self.logger
    shared_logger
  end

  def self.shared_logger
    @shared_logger ||= NewRelic::Agent::Logging::DecoratingLogger.new($stdout)
  end
end
