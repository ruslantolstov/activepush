Activepush.configure do |config|
  # config.ios = :fcm
  # config.android = :fcm
  # config.fcm_server_key = 'xxxx'
  config.sidekiq_queue_name = :activepush
  config.sidekiq_retry = 3
end
