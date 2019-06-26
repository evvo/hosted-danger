module HostedDanger
  class MetricsHandler
    include HTTP::Handler

    SECS = [30, 60, 90]

    @requests : Array(Time)

    def initialize
      @requests = [] of Time

      SECS.each do |sec|
        Metrics.register("http_requests_#{sec}_sec", "counter", "Number of http requests for #{sec} seconds")
        Metrics.register("http_requests_#{sec}_ratio", "gauge", "Ratio of http requests per seconds during #{sec} seconds")
      end
    end

    def new_request
      time_now = Time.now

      @requests.reject! { |t| (time_now - t).to_i > 90 }
      @requests << time_now

      SECS.each do |sec|
        count = @requests.count { |t| (time_now - t).to_i <= sec }
        Metrics.set("http_requests_#{sec}_sec", count)
        Metrics.set("http_requests_#{sec}_ratio", (count.to_f / sec.to_f).round(2))
      end
    end

    def call(context : HTTP::Server::Context)
      new_request

      call_next(context)
    end
  end
end
