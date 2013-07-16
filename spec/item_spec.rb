#encoding: UTF-8

require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::Item do

  before do
    @session = RubyBox::Session.new
    @client  = RubyBox::Client.new(@session)
  end

  describe '#factory' do
    
    it 'creates an object from a web_link hash' do
      web_link = RubyBox::Item.factory(@session, {
        'type' => 'web_link'
      })
      web_link.type.should == 'web_link'
      web_link.instance_of?(RubyBox::WebLink).should == true
    end

    it 'defaults to item object if unknown type' do
      banana = RubyBox::Item.factory(@session, {
        'type' => 'banana'
      })
      banana.type.should == 'banana'
      banana.instance_of?(RubyBox::Item).should == true
    end
  end
end
