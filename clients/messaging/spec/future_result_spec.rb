require 'torquebox/messaging/future_result'

include TorqueBox::Messaging

class FutureResult
  attr_writer :started
  attr_writer :complete
  attr_writer :error
  attr_writer :result
end

describe TorqueBox::Messaging::FutureResult do

  describe "#result" do
    before(:each) do
      @queue = mock( Queue )
      @future = FutureResult.new( @queue )
    end

    it "should raise if it fails to start before timeout" do
      @future.stub(:receive)
      lambda { @future.result( 1 ) }.should raise_error( TimeoutException )
    end

    it "should raise if it fails to complete before timeout" do
      @future.stub(:receive)
      @future.started = true
      lambda { @future.result( 1 ) }.should raise_error( TimeoutException )
    end

    it "should raise if a remote error occurs" do
      @future.stub(:receive)
      @future.started = true
      @future.error = ArgumentError.new
      lambda { @future.result( 1 ) }.should raise_error(ArgumentError )
    end

    it "should return the result if complete" do
      @future.stub(:receive)
      @future.started = true
      @future.complete = true
      @future.result = :success!
      @future.result.should == :success!
    end

  end


end
