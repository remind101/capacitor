module Capacitor
  class Watcher

    def loop_once
      block_on_incoming_signal_list

      start_time = Time.new
      counts = CommandsFetcher.fetch
      process_batch counts
      flush_batch

      instrument "capacitor.loop.time", Time.new - start_time, units:seconds
      instrument "capacitor.loop.object_counters", counts.length
    end

    def loop_forever
      logger.info "Capacitor listening..."
      loop do
        loop_once
      end
    end

    def self.run
      new.loop_forever
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

    # Internal: Expect a counter_id in the form: classname:object_id:field_name
    #
    # Returns: model, object_id, :field
    def parse_counter_id(counter_id)
      begin
        classname, object_id, field_name = counter_id.split(':')
        object_id = object_id.to_i
        raise NameError unless object_id > 0
      rescue Exception => e
        raise NameError, "Invalid counter_id: #{counter_id}"
      end

      begin
        model = classname.constantize
        field = field_name.to_sym
        raise NameError.new("model missing :update_counters") unless model.respond_to? :update_counters
        raise NameError.new("model missing field #{field}") unless model.columns_hash.has_key? field_name
      rescue Exception => e
        raise NameError, "Invalid model.field: #{counter_id} : #{e}"
      end

      [model, object_id, field]
    end

    def process_batch(counts)
      # Take a hash of {'classname:object_id:field_name' => increment,
      # ...} and issue the model calls

      counts.each do |counter_id, count|
        # count can be 0 if the adds and removes balance out.
        count = count.to_i
        next if count == 0

        begin
          model, object_id, field = parse_counter_id counter_id
        rescue Exception => e
          logger.error e
          next
        end

        logger.info "INCREMENT #{model.class.to_s}.#{object_id}.#{field} by #{count}"

        begin
          model.update_counters object_id, field => count
        rescue Exception => e
          logger.error "#{counter_id} exception: #{e}"
        end
      end
    end

  end
end
