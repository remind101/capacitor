require 'spec_helper'

describe Capacitor::Watcher do
  subject (:watcher) { described_class.new }

  describe '#process_batch' do
    it 'updates counters' do
      Post.should_receive(:update_counters).with(123, {:users_count=>1})
      watcher.process_batch({'Post:123:users_count' => 1})
    end
    it 'logs invalid model classnames' do
      watcher.logger.should_receive(:error).with("MissingClassname:123:users_count exception: uninitialized constant MissingClassname")
      watcher.process_batch({'MissingClassname:123:users_count' => 1})
    end
  end

  describe '#loop_once' do
    it 'updates counters' do
      Post.should_receive(:update_counters).with(123, {:users_count=>1})
      redis.hincrby "incoming_hash", "Post:123:users_count", 1
      redis.lpush "incoming_signal_list", "abc"
      watcher.loop_once
    end
  end
end
