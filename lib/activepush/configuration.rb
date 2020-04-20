module Activepush
  class Configuration
    attr_accessor :ios, :android, :fcm_server_key

    def initialize
      @ios = :ios
      @android = :android
      @fcm_server_key = :fcm_server_key
    end
  end
end
