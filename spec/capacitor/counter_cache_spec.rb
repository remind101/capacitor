require 'spec_helper'

describe Capacitor::CounterCache do
  let (:klass) { Post }
  let (:id) { 123 }
  let (:column) { :view_count }
  subject (:counter_cache) { described_class.new klass, id, column }

  describe '#increment' do
    it 'adds one element to hash key in redis' do
      expect { counter_cache.increment }.to change { redis.hlen('incoming_hash') }.from(0).to(1)
    end
    it 'adds one element to signal key in redis' do
      expect { counter_cache.increment }.to change { redis.llen('incoming_signal_list') }.from(0).to(1)
    end
    it 'increments 123 Post key by 1' do
      expect { counter_cache.increment }.to change {
        redis.hget('incoming_hash', 'Post:123:view_count')
      }.from(nil).to("1")
    end
  end
  describe '#decrement' do
    it 'adds one element to hash key in redis' do
      expect { counter_cache.decrement }.to change { redis.hlen('incoming_hash') }.from(0).to(1)
    end
    it 'adds one element to signal key in redis' do
      expect { counter_cache.decrement }.to change { redis.llen('incoming_signal_list') }.from(0).to(1)
    end
    it 'decrements 123 Post key by 1' do
      expect { counter_cache.decrement }.to change {
        redis.hget('incoming_hash', 'Post:123:view_count')
      }.from(nil).to("-1")
    end
  end
end
