module Activepush
  module Notification
    def self.included(base)
      base.extend(ClassMethods)
      base.dynamic_class_attribute :_title, :_body, :_tokens
    end

    module ClassMethods
      ACCESSOR_MUTEX = Mutex.new

      def title(title)
        self._title = title
      end

      def fetch_title(params)
        self._title.class == Proc ? self._title.call(params[:context]) : self._title
      end

      def body(body)
        self._body = body
      end

      def fetch_body(params)
        self._body.class == Proc ? self._body.call(params[:context]) : self._body
      end

      def tokens(&block)
        self._tokens = block
      end

      def fetch_tokens(context)
        raise StandardError.new("Undefined method tokens in #{self.name}") unless self._tokens
        self._tokens.call(context)
      end

      def perform(params)
        Activepush.config.validate_config
        validate_params(params)
        Activepush::Worker.new.perform(title: fetch_title(params), body: fetch_body(params), device_tokens: @device_tokens)
      end

      def perform_async(params)
        Activepush.config.validate_config
        validate_params(params)
        Activepush::Worker.perform_async(title: fetch_title(params), body: fetch_body(params), device_tokens: @device_tokens)
      end

      def perform_in(interval, params)
        Activepush.config.validate_config
        validate_params(params)
        Activepush::Worker.perform_in(interval, title: fetch_title(params), body: fetch_body(params), device_tokens: @device_tokens)
      end

      def validate_params(params)
        if params.is_a?(Hash) && params[:context]
          params = fetch_tokens(params[:context])
        end
        if params.is_a?(String)
          @device_tokens = [params]
        elsif params.is_a?(Array)
          @device_tokens = params
        elsif respond_to?(:tokens)
          raise ArgumentError.new("Send context in perform")
        end
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
