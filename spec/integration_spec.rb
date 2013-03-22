#encoding: UTF-8

require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox do
  before do
    next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.

    WebMock.allow_net_connect!
    
    @session = RubyBox::Session.new({
      api_key: ACCOUNT['api_key'],
      auth_token: ACCOUNT['auth_token']
    })

    @client = RubyBox::Client.new(@session)
  end
    
  describe RubyBox::Session do
    it "raises an AuthError if not client auth fails" do
      next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.

      session = RubyBox::Session.new({
        api_key: 'bad-key',
        auth_token: 'bad-token'
      })

      @bad_client = RubyBox::Client.new(session)

      lambda {@bad_client.root_folder}.should raise_error( RubyBox::AuthError )
    end
    
    it "raises a RequestError if a badly formed request detected by the server" do
      next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.
      stub_request(:get, "https://api.box.com/2.0/folders/0").to_return(:status => 401, :body => '{"type": "error", "status": 401, "message": "baddd req"}', :headers => {})
      lambda {@client.root_folder}.should raise_error( RubyBox::AuthError ) 
    end

    it "raises a ServerError if the server raises a 500 error" do
      next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.
      stub_request(:get, "https://api.box.com/2.0/folders/0").to_return(:status => 503, :body => '{"type": "error", "status": 503, "message": "We messed up! - Box.com"}', :headers => {})
      lambda {@client.root_folder}.should raise_error( RubyBox::ServerError )
    end
  end

  describe RubyBox::Client do
    describe '#root_folder' do
      it "#items returns a lits of items in the root folder" do
        next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.
        items = @client.root_folder.items.to_a
        items.count.should == 6
        items.any? do |item|
          item.type == "folder" && 
          item.id   == "318810303" &&
          item.name == "ruby-box_gem_testing"
        end.should == true
      end
      
      it "returns list of items in the folder id passed in" do
        next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.
        folder = RubyBox::Folder.new(@session, {'id' => '318810303'})
        items = folder.items.to_a
        items.count.should == 3
        items.any? do |item|
          item.type == "file" && 
          item.id   == "2550686921" &&
          item.name == "2513582219_03fb9b67db_b.jpg"
        end.should == true
      end
    end
    
    describe '#file' do
      it "finds the id of a file" do
        next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.
        folder = RubyBox::Folder.new(@session, {'id' => '318810303'})
        file = folder.files( '2513582219_03fb9b67db_b.jpg' ).first
        file.id.should == "2550686921"
      end      
    end
    
    describe '#create' do
      it "creates a folder" do
        next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.

        folder = @client.folder('/ruby-box_gem_testing')
        subfolder = folder.create_subfolder( 'new_folder_created' )
        subfolder.id.should_not == nil

        subfolder.delete
      end

      it "creates a folder with special chars in the name" do
        next unless ACCOUNT['api_key'] # skip these tests if accout.yml does not exist.

     #   folder = @user_api.folder('/ruby-box_gem_testing/!@#$%^&$$()')
     #   folder.delete if folder

#        @folder = @user_api.folder('/ruby-box_gem_testing')
 #       folder = @folder.create( '!@#$%^&$$()' )
  #      folder.root_id.should_not be_nil
      end
    end

  end

=begin
  describe RubyBox::UserAPI do
    describe '#list' do
      it "returns list of items in the folder path passed in" do
        response = @user_api.list('/ruby-box_gem_testing')
        response["total_count"].should eq(4)
        response["entries"].any? do |e|
          e["type"] == "folder" &&
          e["id"]   == "321690909" &&
          e["name"] ==  "cool stuff"
        end.should == true
      end
      
      it 'returns an empty array if no path specified' do
        response = @user_api.list(nil)
        response.should eq({})
      end
      
      it 'returns an empty array if a nonexistent path specified' do
        response = @user_api.list('/none')
        response.should eq({})
      end
    end
    
    describe '#put_data' do
      it "should update an existing file" do
        utf8_file_name = 'кузнецкий_105_а_№2.test'
        fdata = File.open( 'spec/'+utf8_file_name, 'rb' )
        response = @user_api.put_data( fdata, '/ruby-box_gem_testing/cool stuff', utf8_file_name)
        fdata = File.open( 'spec/'+utf8_file_name, 'rb' )
        
        response = @user_api.put_data( fdata, '/ruby-box_gem_testing/cool stuff', utf8_file_name)
        
        response["total_count"].should eq(1)
        response["entries"].all? { |e| e["type"] != "error" }.should be_true
      end
      
      it "should upload a new file" do
        utf8_file_name = 'кузнецкий_105_а_№2.test'
        fdata = File.open( 'spec/' + utf8_file_name, 'rb' )
        
        file_to_delete = @user_api.file( "/ruby-box_gem_testing/cool stuff/#{utf8_file_name}" )
        file_to_delete.delete
        
        response = @user_api.put_data( fdata, '/ruby-box_gem_testing/cool stuff', utf8_file_name)
        
        response["total_count"].should eq(1)
        response["entries"].all? { |e| e["type"] != "error" }.should be_true
      end
    end
  
    describe '#file' do
      it "finds the id of a file" do
        fitem = @user_api.file( '/ruby-box_gem_testing/2513582219_03fb9b67db_b.jpg' )
        fitem.root_id.should eq "2550686921"
      end
      
      it "returns nil if the file doesnt exist" do
        fitem = @user_api.file( 'DoesntExist' )
        fitem.should eq nil
      end    
      
      it "returns nil if the file path doesnt exist" do
        fitem = @user_api.file( '/nodir/DoesntExist' )
        fitem.should eq nil
      end
    end
  
    describe '#create_path' do
      it "creates a path that doesnt exist" do
        last_fitem = @user_api.folder('/ruby-box_gem_testing/cool stuff/екузц/path1/path2')
        last_fitem.delete if last_fitem
        
        response = @user_api.create_path('/ruby-box_gem_testing/cool stuff/екузц/path1/path2')
        response.root_id.should_not be_nil
      end
    end

    describe '#get_file_info' do
      it "returns meta information for a file" do
        meta = @user_api.get_file_info( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        @test_file_path.should include "#{meta['name']}"
        meta['size'].should eq File.size( @test_file_path )
      end
    end
    
    describe '#stream' do
      it "should download file contents" do
        stream = @user_api.stream( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        stream.read.should eq "Test more data"        
      end

      it "should execute content_length_proc lambda with filesize" do
        stream = @user_api.stream(
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
        data = @user_api.download( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        data.should eq "Test more data"
      end
      
      it "returns nil for a nonexistent file" do
        data = @user_api.download( '/ruby-box_gem_testing/doesntexist' )
        data.should eq nil
      end   
    end
  end
=end  
end

