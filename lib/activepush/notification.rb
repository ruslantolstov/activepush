module Activepush
  module Notification
    def self.included(base)
      base.extend(ClassMethods)
      base.dynamic_class_attribute :_title, :_body
    end

    module ClassMethods
      ACCESSOR_MUTEX = Mutex.new

      def title(title)
        self._title = title
      end

      def body(body)
        self._body = body
      end

      def perform(params)
        if params.is_a?(Hash) && params[:context]
          params = send(:tokens, params[:context])
        elsif params.is_a?(String)
          @device_tokens = [params]
        elsif params.is_a?(Array)
          @device_tokens = params
        elsif respond_to?(:tokens)
          raise ArgumentError.new("Send context in perform")
        end

        Activepush::Worker.new.perform(title: _title, body: _body, device_tokens: @device_tokens)
      end

      def perform_async(params)
        if params.is_a?(Hash) && params[:context]
          params = send(:tokens, params[:context])
        elsif params.is_a?(String)
          @device_tokens = [params]
        elsif params.is_a?(Array)
          @device_tokens = params
        elsif respond_to?(:tokens)
          raise ArgumentError.new("Send context in perform")
        end

        Activepush::Worker.perform_async(title: _title, body: _body, device_tokens: @device_tokens)
      end

      def dynamic_class_attribute(*attrs)
        instance_reader = true
        instance_writer = true

        attrs.each do |name|
          synchronized_getter = "__synchronized_#{name}"

          singleton_class.instance_eval do
            undef_method(name) if method_defined?(name) || private_method_defined?(name)
          end

          define_singleton_method(synchronized_getter) { nil }
          singleton_class.class_eval do
            private(synchronized_getter)
          end

          define_singleton_method(name) { ACCESSOR_MUTEX.synchronize { send synchronized_getter } }

          ivar = "@#{name}"

          singleton_class.instance_eval do
            m = "#{name}="
            undef_method(m) if method_defined?(m) || private_method_defined?(m)
          end
          define_singleton_method("#{name}=") do |val|
            singleton_class.class_eval do
              ACCESSOR_MUTEX.synchronize do
                if method_defined?(synchronized_getter) || private_method_defined?(synchronized_getter)
                  undef_method(synchronized_getter)
                end
                define_method(synchronized_getter) { val }
              end
            end

            if singleton_class?
              class_eval do
                undef_method(name) if method_defined?(name) || private_method_defined?(name)
                define_method(name) do
                  if instance_variable_defined? ivar
                    instance_variable_get ivar
                  else
                    singleton_class.send name
                  end
                end
              end
            end
            val
          end

          if instance_reader
            undef_method(name) if method_defined?(name) || private_method_defined?(name)
            define_method(name) do
              if instance_variable_defined?(ivar)
                instance_variable_get ivar
              else
                self.class.public_send name
              end
            end
          end

          next unless instance_writer

          m = "#{name}="
          undef_method(m) if method_defined?(m) || private_method_defined?(m)
          attr_writer name
        end
      end
    end
  end
end
