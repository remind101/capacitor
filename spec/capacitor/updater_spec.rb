require 'spec_helper'

describe Capacitor::Updater do
  let (:model) { Post }
  let (:id) { 123 }
  let (:field) { :view_count }
  let (:count_delta) { 13 }
  let (:counter_id) { 'Post:123:view_count' }
  subject (:updater) { described_class.new( counter_id, count_delta ) }

  describe '#attributes' do
    its(:model) { should == model }
    its(:id) { should == id }
    its(:field) { should == field }
    its(:counter_id) { should == 'Post:123:view_count' }
    its(:count_delta) { should == 13 }
  end

  describe '#update' do
    it 'should call #update_counters on the model' do
      model.should_receive(:update_counters).with(id, field => count_delta)
      updater.update
    end
  end

  describe '#inspect' do
    before { updater.should_receive(:old_count).and_return(1) }
    its(:inspect) { should == 'counter_id=Post:123:view_count old_count=1 count_delta=13' }
  end

  describe '.parse_counter_id' do
    context 'with counter_id Post:123:users_count' do
      subject { described_class.parse_counter_id 'Post:123:users_count' }
      it { should eq([Post, 123, :users_count]) }
    end

    it 'fails to parse counter_id MissingClassname:123:users_count' do
      expect { described_class.parse_counter_id 'MissingClassname:123:users_count' }.to raise_error(NameError)
    end
  end

end
