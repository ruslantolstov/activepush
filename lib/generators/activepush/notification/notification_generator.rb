module Activepush
  module Generators
    class NotificationGenerator < Rails::Generators::Base
      source_root(File.expand_path('../templates', __FILE__))
      argument(:name, type: :string)

      def copy_task
        template(
            'notification.rb.erb',
            "app/notifications/#{file_name}_notification.rb"
        )
      end

      private

      def file_name
        name.underscore
      end
    end
  end
end
