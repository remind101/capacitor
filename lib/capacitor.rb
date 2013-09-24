require 'redis'
require 'redis-namespace'
require 'logger'
require 'capacitor/railtie' if defined?(::Rails)

module Capacitor
  autoload :CounterCache, 'capacitor/counter_cache'
  autoload :CommandsFetcher, 'capacitor/commands_fetcher'
  autoload :Watcher, 'capacitor/watcher'

  class << self
    attr_writer :logger

    def logger
      @logger ||= const_defined?(:Rails) ? Rails.logger : Logger.new(STDOUT)
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
