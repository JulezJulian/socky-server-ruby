module Socky
  module Server
    class Application

      attr_accessor :name, :secret

      class << self
        # list of all known applications
        # @return [Hash] list of applications
        def list
          @list ||= {}
        end

        # find application by name
        # @param [String] name name of application
        # @return [Application] found application or nil
        def find(name)
          list[name]
        end
      end

      # initialize new application
      # @param [String] name application name
      # @param [String] secret application secret key
      # @param [String] webhook url
      def initialize(name, secret, webhook_url)
        @name = name
        @secret = secret
        @webhook_url = webhook_url
        self.class.list[name] ||= self
      end

      # list of all connections for this application
      # @return [Hash] hash of all connections
      def connections
        @connections ||= {}
      end

      # add new connection to application
      # @param [Connection] connection connetion to add
      def add_connection(connection)
        self.connections[connection.id] = connection
      end

      # remove connection from application
      # @param [Connection] connection connection to remove
      def remove_connection(connection)
        self.connections.delete(connection.id)
      end

      def trigger_webhook(event, data)
          return if @webhook_url.nil?

          json_data = { event: event, data: data, timestamp: Time.now.to_f.to_s.gsub('.', '') }.to_json
          digest = OpenSSL::Digest::SHA256.new
          hashed_data = OpenSSL::HMAC.hexdigest(digest, @secret, json_data)

          puts('webhook triggered: ' + event + ': ' +  data.to_s)
          http = EventMachine::HttpRequest.new(@webhook_url).post body: json_data, head: { 'data-hash' => hashed_data }
      end
    end
  end
end
