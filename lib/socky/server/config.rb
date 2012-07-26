require 'yaml'

module Socky
  module Server
    class Config

      # Each config key calls corresponding method with value as param
      def initialize(config = {})
        puts 'initialozing with options: ' + config.to_s
        return unless config.is_a?(Hash)

        # Config file should be readed first
        file = config.delete(:config_file)
        self.config_file(file) unless file.nil?

        config.each { |key, value| self.send(key, value) if self.respond_to?(key) }
      end

      # Enable or disable debug
      def debug(arg)
        Logger.enabled = !!arg
      end

      # List of applications if Hash form where key is app name
      # and value is app secret.
      # @example valid hash
      #   { 'my_app_name' => 'my_secret' }
      def applications(arg)
        raise ArgumentError, 'expected Hash' unless arg.is_a?(Hash)

        arg.each do |app_name, options|
          if options.is_a?(Hash)
            Socky::Server::Application.new(app_name.to_s, options['secret'], options['webhook_url'])
          else
            Socky::Server::Application.new(app_name.to_s, options, nil)
          end
        end
      end

      # Reads config file
      # This should be evaluated before other methods to prevent
      # overriding settings by config ones(config should have lower priority)
      def config_file(path)
        raise ArgumentError, 'expected String' unless path.is_a?(String)
        raise ArgumentError, "config file not found: #{path}" unless File.exists?(path)

        begin
          config = YAML.load_file(path)
        rescue Exception
          raise ArgumentError, 'invalid config file'
        end

        Config.new(config)
      end
    end
  end
end
