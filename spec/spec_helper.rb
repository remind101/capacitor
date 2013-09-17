require 'bundler/setup'
Bundler.require

def redis
  Capacitor.redis
end

RSpec.configure do |config|
  config.before do
    redis.flushdb
  end
end

Capacitor.logger = Logger.new nil

class Post
  def self.update_counters(*args)
  end
end
