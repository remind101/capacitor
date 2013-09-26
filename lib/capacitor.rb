require 'redis'
require 'redis-namespace'
require 'logger'

module Capacitor
  autoload :CounterCache, 'capacitor/counter_cache'
  autoload :CommandsFetcher, 'capacitor/commands_fetcher'
  autoload :Watcher, 'capacitor/watcher'
  autoload :Updater, 'capacitor/updater'

  class << self
    attr_writer :logger

    def logger
      @logger ||= const_defined?(:Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def log_level=(level)
      return unless level
      begin
        level = Logger.const_get level.upcase if level.is_a?(String)
        logger.level = level
      rescue Exception => e
        logger.error "Unable to set log level to #{level} - #{e}"
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
