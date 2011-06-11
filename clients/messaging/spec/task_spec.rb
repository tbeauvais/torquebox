require 'torquebox/messaging/future_responder'
require 'torquebox/messaging/future_result'
require 'torquebox/messaging/destination'
require 'torquebox/messaging/task'

class MyTestTask < TorqueBox::Messaging::Task
  attr_accessor :payload
end

class TorqueBox::Messaging::FutureResponder
  def respond
    yield
  end
end

describe TorqueBox::Messaging::Task do


  describe '#async' do
    before(:each) do
      TorqueBox::Messaging::FutureResult.stub(:unique_id).and_return('1234')
      @send_queue = mock('queue')
      @send_queue.stub(:publish)
      TorqueBox::Messaging::Queue.should_receive(:new).with(MyTestTask.queue_name).and_return(@send_queue)
    end

    it "should send payload correctly" do
      expectation = [{:method => :payload=, :payload => {:foo => 'bar'}, :future_id => '1234', :future_queue => MyTestTask.queue_name}, { }]
      @send_queue.should_receive(:publish).with(*expectation)
      
      MyTestTask.async(:payload=, :foo => 'bar')
    end

    it "should handle nil payload as empty hash" do
      @send_queue.should_receive(:publish).with(hash_including(:payload => {}), {})

      MyTestTask.async(:payload=)
    end

    it "should return a future" do
      result = MyTestTask.async(:payload=)
      result.is_a?(TorqueBox::Messaging::FutureResult).should be_true
    end
  end

  describe "#process!" do
    it "should process payload correctly" do
      expectation = {:method => :payload=, :payload => {:foo => 'bar'}, :future_id => '1234', :future_queue => MyTestTask.queue_name}
      message = mock("message")
      message.should_receive(:decode).and_return(expectation)

      task = MyTestTask.new
      task.process! message
      task.payload[:foo].should == 'bar'
    end
  end
  
  describe "queue_name" do
    before(:each) do
      ENV['TORQUEBOX_APP_NAME'] = 'app_name'
    end

    after(:each) do
      ENV.delete('TORQUEBOX_APP_NAME')
    end

    it "should derive the queue name from the class name" do
      MyTestTask.queue_name.should =~ %r{/my_test$}
    end

    it "should include the app name in the queue name" do
      MyTestTask.queue_name.should =~ %r{/app_name/}
    end

    {
      'FooTask' => 'foo',
      'FooBarTask' => 'foo_bar',
      'Foo::BarBazTask' => 'foo/bar_baz'
    }.each do |given, expected|
      it "should generate the proper queue name for #{given}" do
        MyTestTask.stub(:name).and_return(given)
        MyTestTask.queue_name.should == "/queues/torquebox/app_name/tasks/#{expected}"
      end
    end

  end
end
