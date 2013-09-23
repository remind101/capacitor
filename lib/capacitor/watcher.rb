require "active_support/core_ext/string/inflections"
require 'formatted-metrics'

module Capacitor
  class Watcher

    def loop_once
      commands_fetcher.block_on_incoming_signal_list
      start_time = Time.new
      counts = commands_fetcher.retrieve_batch
      process_batch counts
      commands_fetcher.flush_batch

      instrument "capacitor.loop.time", Time.new - start_time, units:'seconds'
      instrument "capacitor.loop.object_counters", counts.length
    end

    def loop_forever
      logger.info "Capacitor listening..."

      loop do
        loop_once
        pause if pause_time
      end
    end

    def pause
      logger.debug "Capacitor pausing for #{pause_time}s"
      sleep pause_time
    end

    def pause_time
      ENV['CAPACITOR_SLEEP'] ? ENV['CAPACITOR_SLEEP'].to_f : nil
    end

    def commands_fetcher
      @commands_fetcher ||= CommandsFetcher.new
    end

    def self.run
      new.loop_forever
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
        rescue Exception => e
          logger.error "#{counter_id} exception: #{e}"
        end
      end
    end

    private

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
