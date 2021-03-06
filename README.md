# Activepush
Activepush is a tool which allows you to make your Push Notifications logic structured. Simple DSL and background processing with [Sidekiq](https://github.com/mperham/sidekiq).

**Providers**
* Firebase Cloud Messaging(FCM) - iOS, Android
* Apple Push Notification Service(APNs) - iOS

## Requirements

* Sidekiq

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activepush'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activepush
    $ rails g activepush:install

## Set up
```diff
# config/initializers/activepush.rb
Activepush.configure do |config|
  # config.ios = :fcm
  # config.android = :fcm
  # config.fcm_server_key = 'xxxx'
  config.sidekiq_queue_name = :activepush
  config.sidekiq_retry = 3
end
```

## Usage

$ rails g activepush:notification greeting

```ruby
class GreetingNotification
  include Activepush::Notification

  title 'Your title'
  body 'Your body'

  # tokens(context)
  #   Your token logic returns device_token or array
  #   context.user.devices.last_active.pluck(:device_token)
  # end
end

# send notification async (with token)
GreetingNotification.perform_async('devise_token')

# send notification async (with array of tokens)
GreetingNotification.perform_async(['devise_token0', 'devise_token1'])

# send notification async (with context)
GreetingNotification.perform_async(context: user)

# send immediately
GreetingNotification.perform('devise_token')
```
## Dynamic data

```ruby
class WelcomeBackNotification
  include Activepush::Notification

  title -> (context) { "Welcome back #{context[:username]}" }
  body -> (context) { "You have missed #{context[:messages]} messages" }

  tokens(context)
     context[:user].devices.last_active.pluck(:device_token)
  end
end

WelcomeBackNotification.perform_async(context: { username: 'tom99', messages: 5, user: current_user })
```



## Contributing

1. Fork it ( link )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The MIT License
