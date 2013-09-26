require "active_support/core_ext/string/inflections"
require 'formatted-metrics'

module Capacitor
  class Watcher

    def loop_once
      commands_fetcher.block_on_incoming_signal_list

      begin
        @working = true
        start_time = Time.new
        Capacitor.log_level= log_level
        counts = commands_fetcher.retrieve_batch
        with_pause
        process_batch counts
        commands_fetcher.flush_batch

        instrument "capacitor.loop.time", Time.new - start_time, units:'seconds'
        instrument "capacitor.loop.object_counters", counts.length

        shut_down! if shut_down?
      ensure
        @working = false
      end
    end

    def loop_forever
      logger.info "Capacitor listening..."
      redis.set "capacitor_start", Time.new.to_s

      loop do
        loop_once
      end
    end

    def with_pause
      yield if block_given?

      if time = pause_time
        logger.debug "Capacitor pausing for #{time}s"
        sleep time
      end
    end

    def pause_time
      time = redis.get "pause_time"
      time ? time.to_f : nil
    end

    def log_level
      redis.get "log_level"
    end

    def commands_fetcher
      @commands_fetcher ||= CommandsFetcher.new
    end

    def self.run
      watcher = new

      %w(INT TERM).each do |signal|
        trap signal do
          watcher.handle_signal(signal)
        end
      end

      watcher.loop_forever
    end

    def logger
      Capacitor.logger
    end

    # Internal: Expect a counter_id in the form: classname:object_id:field_name
    #
    # Returns: model, object_id, :field
    def parse_counter_id(counter_id)
      classname, object_id, field_name = counter_id.split(':')
      [classname.constantize, object_id.to_i, field_name.to_sym]
    end

    # Public: update_counters on models
    #
    # counts - {'classname:id:field_name' => increment, ...}
    #
    # Returns: nothing
    def process_batch(counts)

      counts.each do |counter_id, count|
        # count can be 0 if the adds and removes balance out.
        count = count.to_i
        next if count == 0

        begin
          model, id, field = parse_counter_id counter_id
          model.update_counters id, field => count
          if logger.level == Logger::DEBUG
            instance = model.find id
            old_count = instance.send(field.to_sym)
            logger.debug "update_counter #{counter_id} #{count} #{old_count}"
          end
        rescue Exception => e
          logger.error "#{counter_id} exception: #{e}"
        end
      end
    end

    def handle_signal(signal)
      case signal
      when 'INT', 'TERM'
        working? ? shut_down : shut_down!
      end
    end

    private

    def working?
      @working
    end

    def shut_down
      @shut_down = true
    end

    def shut_down!
      exit(0)
    end

    def shut_down?
      @shut_down
    end

    def delay_warning_threshold
      0.003
    end

    def redis
      Capacitor.redis
    end

    def instrument(*args, &block)
      Metrics.instrument *args, &block
    end
  end
end
