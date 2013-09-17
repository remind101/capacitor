module Capacitor

  class CommandsFetcher

    def fetch
      new.retrieve_batch
    end

    def blocking_timeout
      60
    end

    def redis
      Capacitor.redis
    end

    def logger
      Capacitor.logger
    end

    def incoming_signal_list
      redis.blpop "incoming_signal_list", blocking_timeout
    end

    def block_on_incoming_signal_list
      false until incoming_signal_list
      flush_incoming_signal_list
    end

    def flush_incoming_signal_list
      redis.del "incoming_signal_list"
    end

    def retrieve_existing_batch
      batch = redis.hgetall "processing_hash"
      if !batch.empty?
        redis.rename "processing_hash", "retry_hash"
        logger.error "processing_hash moved to retry_hash"
        batch
      else
        nil
      end
    end

    def retrieve_current_batch
      begin
        result = redis.rename "incoming_hash", "processing_hash"
      rescue Exception => e
        # This means we got a signal without getting data, which is
        # probably okay due to the harmless race condition, but might
        # warrant investigation later, so let's log it and move on.
        logger.warn "empty incoming_hash in retrieve_batch"
        return {}
      end
      redis.hgetall "processing_hash"
    end

    # When things are working well
    # :incoming_hash -> :processing_hash -> flush()
    #
    # If a batch fails once
    # :processing_hash -> :retry_hash -> flush()
    #
    # If a batch fails again
    # :retry_hash -> :failed_hash_keys -> flush()
    # then start over with :incoming_hash
    def retrieve_batch
      flush_retried_batch
      return retrieve_existing_batch || retrieve_current_batch
    end

    def flush_batch
      # Safely processed now, kill the batch in redis
      redis.del "processing_hash", "retry_hash"
    end

    def flush_retried_batch
      if redis.hlen("retry_hash") > 0
        failure = 'failure:' + Time.new.utc.to_f.to_s
        redis.rename "retry_hash", failure
        redis.lpush "failed_hash_keys", failure
        logger.error "retry_hash moved to #{failure}"
      end
    end
  end
end
