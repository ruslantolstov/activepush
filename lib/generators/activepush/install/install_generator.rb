require "rails/generators"

module Activepush
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def add_initializer
      template("activepush.rb", "config/initializers/activepush.rb")
    end
  end
end
