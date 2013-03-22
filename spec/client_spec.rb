#encoding: UTF-8

require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::Client do
  before do
    @session = RubyBox::Session.new
  end

  describe '#split_path' do
    it "returns the appropriate path" do
      client = RubyBox::Client.new(@session)
      client.split_path('foo/bar').should == ['foo', 'bar']
    end

    it "leading / is ignored" do
      client = RubyBox::Client.new(@session)
      client.split_path('/foo/bar').should == ['foo', 'bar']
    end

    it "trailing / is ignored" do
      client = RubyBox::Client.new(@session)
      client.split_path('foo/bar/').should == ['foo', 'bar']
    end
  end
end
