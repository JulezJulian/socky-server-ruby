module Socky
  module Server
    class WebhookHandler

      def initialize(application)
      	@application = application
      	@collecting = 0
      	@events = []
      end

      def trigger(event, data)
          @events << { event: event, data: data, timestamp: Time.now.to_f.to_s.gsub('.', '') }

          send_data if @collecting == 0
      end

      def group(&block)
        @collecting = @collecting + 1
        yield(self)
        @collecting = @collecting - 1
        send_data
      end

      protected
        def send_data
          return if @application.webhook_url.nil?
          return if @events.empty?

          json_data = @events.to_json
          hash = sign_data(json_data)

          EventMachine::HttpRequest.new(@application.webhook_url).post body: json_data, head: { 'data-hash' => hash } rescue nil

          @events.clear
        end

        def sign_data(data)
          salt = Digest::MD5.hexdigest(rand.to_s)
          data_to_sign = [salt, data].collect(&:to_s).join(':')
          digest = OpenSSL::Digest::SHA256.new
          hashed_data = OpenSSL::HMAC.hexdigest(digest, @application.secret, data_to_sign)
          return [salt, hashed_data].join(':')
        end
    end
  end
end
