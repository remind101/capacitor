require 'spec_helper'

describe Capacitor::CommandsFetcher do
  subject (:commands_fetcher) { described_class.new }

  describe '#incoming_signal_list' do
    context 'when incoming_signal_list has items' do
      subject { commands_fetcher.incoming_signal_list }
      before {
        redis.lpush "incoming_signal_list", "abc"
        commands_fetcher.stub blocking_timeout: 1
      }
      it { should_not be_nil }
    end
    context 'when incoming_signal_list is empty' do
      subject { commands_fetcher.incoming_signal_list }
      before { commands_fetcher.stub blocking_timeout: 1 }
      it { should be_nil }
    end
  end

  describe '#retrieve_existing_batch' do
    context 'when unprocessed batch waiting' do
      subject {
        commands_fetcher.retrieve_batch
        # Normally, the retrieved batch would get flushed before a new retrieval
        commands_fetcher.retrieve_existing_batch
      }
      before { redis.hincrby "incoming_hash", "Post:123:users_count", 1 }
      it { should eq("Post:123:users_count" => "1") }
    end
  end

  describe '#retrieve_batch' do
    context 'when normal batch waiting' do
      subject { commands_fetcher.retrieve_batch }
      before { redis.hincrby "incoming_hash", "Post:123:users_count", 1 }
      it { should eq("Post:123:users_count" => "1") }
    end
    context 'when unprocessed batch fails' do
      subject {
        commands_fetcher.retrieve_batch
        commands_fetcher.retrieve_batch
        commands_fetcher.retrieve_batch
      }
      before { redis.hincrby "incoming_hash", "Post:123:users_count", 1 }
      it { should eq({}) }
    end
  end


  describe '#flush_batch' do
    before {
      redis.hincrby "incoming_hash", "Post:123:users_count", 1
      commands_fetcher.retrieve_batch
    }
    it 'flushes redis.processing_hash' do
      expect { commands_fetcher.flush_batch }.to change { redis.hlen "processing_hash" }.from(1).to(0)
    end
  end

  describe '#flush_retried_batch' do
    before {
      redis.hincrby "incoming_hash", "Post:123:users_count", 1
      commands_fetcher.retrieve_batch
      commands_fetcher.retrieve_batch
    }
    it 'flushes redis.retry_hash' do
      expect { commands_fetcher.flush_retried_batch }.to change { redis.hlen "retry_hash" }.from(1).to(0)
    end
  end
end
