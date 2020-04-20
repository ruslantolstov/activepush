module Activepush
  class Worker
    include Sidekiq::Worker
    sidekiq_options queue: "activepush", retry: 3

    def perform(params = {})
      @params = params.symbolize_keys!
      if Activepush.config.fcm_server_key
        require 'fcm'
        fcm = FCM.new(Activepush.config.fcm_server_key, timeout: 3)

        options = { "notification": {
          "title": @params[:title],
          "body": @params[:body]
        } }
        fcm.send(@params[:device_tokens], options)
      end
    end
  end
end
