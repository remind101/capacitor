module Capacitor
  class Updater
    attr_reader :model, :id, :field, :count_delta, :counter_id

    def initialize(counter_id, count_delta)
      @count_delta = count_delta.to_i
      @counter_id = counter_id
      @model, @id, @field = self.class.parse_counter_id(counter_id)
    end

    # Public: Updates the counter with the new count delta
    #
    # If count_delta is zero, does nothing
    def update
      return if @count_delta.zero?
      @model.update_counters(@id, @field => @count_delta)
    end

    # Public: Returns the counter value from the database
    def old_count
      @model.find(@id)[@field]
    end

    # Public: Returns a string of useful debug info
    def inspect
      "counter_id=#{counter_id} old_count=#{old_count} count_delta=#{count_delta}"
    end

    # Internal: Expect a counter_id in the form: classname:object_id:field_name
    #
    # Returns: model, object_id, :field
    def self.parse_counter_id(counter_id)
      classname, object_id, field_name = counter_id.split(':')
      [classname.constantize, object_id.to_i, field_name.to_sym]
    end
  end
end