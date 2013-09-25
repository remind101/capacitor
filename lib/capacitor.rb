require 'redis'
require 'redis-namespace'
require 'logger'

module Capacitor
  autoload :CounterCache, 'capacitor/counter_cache'
  autoload :CommandsFetcher, 'capacitor/commands_fetcher'
  autoload :Watcher, 'capacitor/watcher'

  class << self
    attr_writer :logger

    def logger
      @logger ||= const_defined?(:Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def log_level=(level)
      if level != nil && level != @level
        begin
          logger.level = Logger.const_get level
          @level = level
        rescue Exception => e
          logger.error "Unable to set log level to #{level} - #{e}"
        end
      end
    end

    def redis=(redis)
      @redis = Redis::Namespace.new :capacitor, redis: redis
    end

    def redis
      @redis ||= Redis::Namespace.new :capacitor, redis: Redis.current
    end

    def run
      Watcher.run
    end

  end
end
