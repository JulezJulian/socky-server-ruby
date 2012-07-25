module Socky
  module Server
    class WebhookHandler

      def initialize(application)
        @application = application
        @collecting = 0
        @events = []
        @mutex = Mutex.new
      end

      def trigger(event, data)
        event = { event: event, data: data, timestamp: Time.now.to_f.to_s.gsub('.', '') }

        puts 'sending event: ' + event.to_json

        if @collecting > 0
          puts '6'
          @events << event
        else
          puts '7'
          send_data([event])
        end
      end

      def group(&block)
        events_to_send = []
        puts '3'
        @mutex.synchronize do
          @collecting = @collecting + 1
          yield(self)
          @collecting = @collecting - 1
          events_to_send = @events.dup
          @events.clear
        end
puts '4'
        send_data(events_to_send) unless events_to_send.empty?
      end

      protected
        def send_data(events)
          puts '2'
          return if @application.webhook_url.nil?

          puts '1'

          json_data = events.to_json
          hash = sign_data(json_data)

          puts "sending data: " + json_data

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
