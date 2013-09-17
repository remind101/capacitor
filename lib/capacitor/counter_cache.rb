module Capacitor
  # Public: The public interface to incrementing and decrementing the counter cache
  #
  # klass  - ActiveRecord class
  # id     - record id
  # column - counter column symbol
  class CounterCache
    def initialize(klass, id, column)
      @classname = klass.to_s
      @id = id.to_s
      @column = column
    end

    # Public: increment `column` by 1
    #
    # Returns: nothing
    def increment
      enqueue_count_change 1
    end

    # Public: decrement `column` by 1
    #
    # Returns: nothing
    def decrement
      enqueue_count_change -1
    end

  private

    attr_accessor :classname, :id, :column

    def redis
      Capacitor.redis
    end

    def logger
      Rails.logger
    end

    def enqueue_count_change(delta)
      redis.pipelined do
        redis.hincrby "incoming_hash", counter_id, delta
        redis.lpush "incoming_signal_list", counter_id
      end
    end

    def counter_id
      [classname, id, column.to_s].join(':')
    end
  end
end
