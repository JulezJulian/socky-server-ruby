module Socky
  module Server
    class WebhookHandler

      def initialize(application)
        @application = application
        @collecting = false
        @events = []
        @mutex = Mutex.new
      end

      def trigger(event, data)
        event = { event: event, data: data, timestamp: Time.now.to_f.to_s.gsub('.', '') }

        if @collecting
          @events << event
        else
          send_data([event])
        end
      end

      def group(&block)
        yield(self) and return if @collecting

        events_to_send = []

        @mutex.synchronize do
          @collecting = true
          yield(self)
          @collecting = false
          events_to_send = @events.dup
          @events.clear
        end

        send_data(events_to_send) unless events_to_send.empty?
      end

      protected
        def send_data(events)
          return if @application.webhook_url.nil?

          json_data = events.to_json
          hash = sign_data(json_data)

          EventMachine::HttpRequest.new(@application.webhook_url).post body: json_data, head: { 'data-hash' => hash } rescue nil
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
