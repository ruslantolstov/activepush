require "activepush/version"
require "activepush/configuration"
require "activepush/worker"
require "activepush/notification"
module Activepush
  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Configuration.new
  end
end
