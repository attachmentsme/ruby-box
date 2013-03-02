#encoding: UTF-8

require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox do
  before do
    WebMock.allow_net_connect!
    
    xport = RubyBox::Xport.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    @folder = RubyBox::FFolder.new( xport )
    @user_api = RubyBox::UserAPI.new( xport )
    @test_file_path = "./spec/кузнецкий_105_а_№2.test"
  end
    
  describe RubyBox::FFolder do
    it "raises an AuthError if not client auth fails" do
      xport = RubyBox::Xport.new(ACCOUNT['api_key'], ACCOUNT['auth_token'] + 'x')
      @bad_folder = RubyBox::FFolder.new( xport )    
      lambda {@bad_folder.list}.should raise_error( RubyBox::AuthError )
    end
    
    it "raises a RequestError if a badly formed request detected by the server" do
      stub_request(:get, "https://api.box.com/2.0/folders/0/items").to_return(:status => 401, :body => '{"type": "error", "status": 401, "message": "baddd req"}', :headers => {})
      lambda {@folder.list}.should raise_error( RubyBox::RequestError ) 
    end
    
    it "raises a ServerError if the server raises a 500 error" do
      stub_request(:get, "https://api.box.com/2.0/folders/0/items").to_return(:status => 503, :body => '{"type": "error", "status": 503, "message": "We messed up! - Box.com"}', :headers => {})
      lambda {@folder.list}.should raise_error( RubyBox::ServerError )
    end
  end
  
  describe RubyBox::FFolder do
    describe '#list' do
      it "returns list of items in the root folder if no arguments given" do
        response = @folder.list
        response["total_count"].should eq(6)
        response["entries"].any? do |e|
          e["type"] == "folder" && 
          e["id"]   == "318810303" &&
          e["name"] == "ruby-box_gem_testing"
        end.should == true
      end
      
      it "returns list of items in the folder id passed in" do
        @folder.root_id = 318810303
        response = @folder.list
        response["total_count"].should eq(4)
        response["entries"].any? do |e|
          e["type"] == "file" && 
          e["id"]   == "2550686921" &&
          e["name"] == "2513582219_03fb9b67db_b.jpg"
        end.should == true
      end
    
      it "returns appropriately if the path does not exist" do 
        @folder.root_id = 207492335
        expect { @folder.list }.to raise_error(RubyBox::ObjectNotFound)
      end
    end
    
    describe '#file' do
      it "finds the id of a file" do
        @folder.root_id = 318810303
        ffile = @folder.file( '2513582219_03fb9b67db_b.jpg' )
        ffile.root_id.should == "2550686921"
      end
      
      it "returns a file with nil root_id if not found" do
        @folder.root_id = 318810303
        ffile = @folder.file( 'doesntexist.jpg' )
        ffile.root_id.should be_nil
      end
    end
        
    describe '#folder' do
      it "finds the id of a folder" do
        fitem = @folder.folder( 'ruby-box_gem_testing' )
        fitem.root_id.should eq "318810303"
      end

      it "returns nil if the folder doesnt exist" do
        fitem = @folder.folder( 'DoesntExist' )
        fitem.root_id.should eq nil
      end    
    end
    
    describe '#create' do
      it "creates a folder" do
        folder = @user_api.folder('/ruby-box_gem_testing/new_folder_created')
        folder.delete if folder

        @folder = @user_api.folder('/ruby-box_gem_testing')
        folder = @folder.create( 'new_folder_created' )
        folder.root_id.should_not be_nil
      end

      it "creates a folder with special chars in the name" do
        folder = @user_api.folder('/ruby-box_gem_testing/!@#$%^&$$()')
        folder.delete if folder

        @folder = @user_api.folder('/ruby-box_gem_testing')
        folder = @folder.create( '!@#$%^&$$()' )
        folder.root_id.should_not be_nil
      end
    end
  end

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
  
end

