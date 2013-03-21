#encoding: UTF-8

require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::Client do
  before do
    @session = RubyBox::Session.new
  end

  describe '#build_path' do
    it "returns the appropriate path" do
      client = RubyBox::Client.new(@session)
      client.build_path('foo/bar').should == ['foo', 'bar']
    end
  end
end
