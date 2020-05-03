require 'fcm'

module Activepush
  class Worker
    include Sidekiq::Worker
    sidekiq_options queue: 'activepush', retry: 3

    def perform(params = {})
      @params = params.symbolize_keys!
      fcm_request
    end


    private

    def fcm_request
      if Activepush.config.fcm_server_key
        fcm = FCM.new(Activepush.config.fcm_server_key, timeout: 3)
        options = { notification: { title: @params[:title], body: @params[:body]} }
        @response = fcm.send(@params[:device_tokens], options)
        raise StandardError.new(@response[:body]) if fcm_response_failed?
      end
    end

    def fcm_response_failed?
      JSON.parse(@response[:body])['failure'].positive?
    end
  end
end
