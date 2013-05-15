#encoding: UTF-8

require 'spec_helper'
require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox, :skip => true do
  before do
    WebMock.allow_net_connect!
    
    @session = RubyBox::Session.new({
      api_key: ACCOUNT['api_key'],
      auth_token: ACCOUNT['auth_token']
    })

    @client = RubyBox::Client.new(@session)

    # Create a file with a UTF-8 name for testing.
    # This is not checked in, as UTF-8 causes issues with
    # Windows (lame).
    f = File.new('./spec/fixtures/遠志教授.jpg', 'w')
    f.puts('Hello World!')
    f.close()
  end

  after do
    File.delete('./spec/fixtures/遠志教授.jpg')
  end
    
  it "raises an AuthError if not client auth fails" do
    session = RubyBox::Session.new({
      api_key: 'bad-key',
      auth_token: 'bad-token'
    })

    @bad_client = RubyBox::Client.new(session)

    lambda {@bad_client.root_folder}.should raise_error( RubyBox::AuthError )
  end
  
  it "raises a RequestError if a badly formed request detected by the server" do
    stub_request(:get, "https://api.box.com/2.0/folders/0").to_return(:status => 401, :body => '{"type": "error", "status": 401, "message": "baddd req"}', :headers => {})
    lambda {@client.root_folder}.should raise_error( RubyBox::AuthError ) 
  end

  it "raises a ServerError if the server raises a 500 error" do
    stub_request(:get, "https://api.box.com/2.0/folders/0").to_return(:status => 503, :body => '{"type": "error", "status": 503, "message": "We messed up! - Box.com"}', :headers => {})
    lambda {@client.root_folder}.should raise_error( RubyBox::ServerError )
  end

  describe RubyBox::Folder do
    describe '#root_folder' do
      it "#items returns a lits of items in the root folder" do
        items = @client.root_folder.items.to_a
        items.count.should == 6
        items.any? do |item|
          item.type == "folder" && 
          item.id   == "318810303" &&
          item.name == "ruby-box_gem_testing"
        end.should == true
      end
      
      it "returns list of items in the folder id passed in" do
        folder = RubyBox::Folder.new(@session, {'id' => '318810303'})
        items = folder.items.to_a
        items.count.should == 2
        items.any? do |item|
          item.type == "file" && 
          item.id   == "2550686921" &&
          item.name == "2513582219_03fb9b67db_b.jpg"
        end.should == true
      end
    end
    
    describe '#file' do
      it "finds the id of a file" do
        folder = RubyBox::Folder.new(@session, {'id' => '318810303'})
        file = folder.files( '2513582219_03fb9b67db_b.jpg' ).first
        file.id.should == "2550686921"
      end      
    end
    
    describe '#create' do
      it "creates a folder" do
        folder = @client.folder('/ruby-box_gem_testing')
        subfolder = folder.create_subfolder( 'new_folder_created' )
        subfolder.id.should_not == nil

        subfolder.delete
      end

      it "creates a folder with special chars in the name" do
        folder = @client.folder('/ruby-box_gem_testing')
        subfolder = folder.create_subfolder( '!@#$%^&$$()' )
        subfolder.id.should_not == nil

        subfolder.delete
      end
    end

  end

  describe RubyBox::Client do

    describe '#put_data' do
      it "should update an existing file" do
        utf8_file_name = '遠志教授.jpg'
        fdata = File.open( 'spec/fixtures/' + utf8_file_name, 'rb' )
        response = @client.upload_data('/ruby-box_gem_testing/cool stuff/遠志教授.jpg', fdata)
        fdata = File.open( 'spec/fixtures/' + utf8_file_name, 'rb' )
        
        file = @client.upload_data('/ruby-box_gem_testing/cool stuff/遠志教授.jpg', fdata)
        file.name.should == '遠志教授.jpg'
        file.delete
      end
      
      it "should upload a new file" do
        utf8_file_name = '遠志教授.jpg'
        file = @client.upload_file('spec/fixtures/' + utf8_file_name, '/ruby-box_gem_testing/cool stuff/')
        file.name.should == '遠志教授.jpg'
        file.delete        
      end
    end
  
    describe '#create_folder' do
      it "creates a path that doesnt exist" do
        folder = @client.create_folder('/ruby-box_gem_testing/cool stuff/екузц/path1/path2')
        folder.id.should_not == nil
        folder.delete if folder
      end
    end

    describe '#get_file_info' do
      it "returns meta information for a file" do
        file = @client.file( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        file.size.should == 14
      end
    end
    
    describe '#stream' do
      it "should download file contents" do
        stream = @client.stream( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        stream.read.should eq "Test more data"        
      end

      it "should execute content_length_proc lambda with filesize" do
        stream = @client.stream(
          '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test',
          :content_length_proc => lambda {|filesize|
            filesize.should == 14
          }
        )
        stream.read.should eq "Test more data"                
      end
    end

    describe '#download' do
      it "finds the id of a file" do
        data = @client.download( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        data.should eq "Test more data"
      end
      
      it "returns nil for a nonexistent file" do
        data = @client.download( '/ruby-box_gem_testing/doesntexist' )
        data.should eq nil
      end   
    end
  end
end

