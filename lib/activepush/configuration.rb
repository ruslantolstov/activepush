module Activepush
  class Configuration
    attr_accessor :ios, :android, :fcm_server_key, :sidekiq_queue_name, :sidekiq_retry

    def initialize
      @sidekiq_queue_name = :activepush
      @sidekiq_retry = 3
    end

    def validate_config
      raise StandardError.new("Invalid android provider in initializers/activepush.rb") if android && android != :fcm
      if android && android == :fcm
        raise StandardError.new("Not defined fcm_server_key in initializers/activepush.rb") unless fcm_server_key
      end

      raise StandardError.new("Invalid ios provider in initializers/activepush.rb") if ios && ios != :fcm
      if ios && ios == :fcm
        raise StandardError.new("Not defined fcm_server_key in initializers/activepush.rb") unless fcm_server_key
      end
    end

    def ios_enabled?
      ios.present?
    end

    def android_enabled?
      android.present?
    end
  end
end
