#encoding: UTF-8

require 'spec_helper'
require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::Client do
  before do
    @session = RubyBox::Session.new
  end

  describe '#folder' do
    it "should return root folder as default behavior for paths such as ./" do
      RubyBox::Client.any_instance.should_receive(:root_folder).exactly(4).times
      client = RubyBox::Client.new(@session)
      client.folder()
      client.folder('.')
      client.folder('./')
      client.folder('/')
    end
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
  
  describe '#create_folder' do
    it 'doesnt call folder.create_folder if the folder exists' do
      client = RubyBox::Client.new(@session)
      mock_root_folder = mock( Object )
      test_folder = mock( Object )
      mock_root_folder.should_receive(:folders).and_return([test_folder])
      mock_root_folder.should_not_receive(:create_subfolder)
      client.should_receive(:root_folder).and_return(mock_root_folder)
      result = client.create_folder( '/test0')
      result.should == test_folder
    end
    
    it 'calls folder.create_folder if the folder does not exist' do
      client = RubyBox::Client.new(@session)
      mock_root_folder = mock( Object )
      test_folder = mock( Object )
      mock_root_folder.should_receive(:folders).and_return([])
      mock_root_folder.should_receive(:create_subfolder).and_return(test_folder)
      client.should_receive(:root_folder).and_return(mock_root_folder)
      result = client.create_folder( '/test0')
      result.should == test_folder
    end
  end
end
