#encoding: UTF-8

require 'helper/account'
require 'ruby-box'

describe RubyBox do
  before do
    xport = RubyBox::Xport.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    @folder = RubyBox::FFolder.new( xport )
    @user_api = RubyBox::UserAPI.new( xport )
  end
    
  describe RubyBox::FFolder do
  
    describe '#list' do
      it "returns list of items in the root folder if no arguments given" do
        response = @folder.list
        response["total_count"].should eq(2)
        response["entries"].should include({"type"=>"folder","id"=>"318810303","sequence_id"=>"0","name"=>"MyDocs"})
      end
      
      it "returns list of items in the folder id passed in" do
        @folder.root_id = 318810303
        response = @folder.list
        response["total_count"].should eq(3)
        response["entries"].should include({"type"=>"file", "id"=>"2550686921", "sequence_id"=>"1", "name"=>"2513582219_03fb9b67db_b.jpg"})
      end
    
      it "returns appropriately if the path does not exist" do 
        @folder.root_id = 207492335
        expect { @folder.list }.to raise_error(RubyBox::ObjectNotFound)
      end
    end
    
    describe '#get_folder_id' do
      it "finds the id of a folder" do
        fitem = @folder.folder( 'MyDocs' )
        fitem.root_id.should eq "318810303"
      end

      it "returns nil if the folder doesnt exist" do
        fitem = @folder.folder( 'DoesntExist' )
        fitem.root_id.should eq nil
      end    
    end
    
    describe '#create' do
      it "creates a folder" do
        folder = @user_api.folder('/MyDocs/new_folder_created')
        folder.delete

        @folder.root_id = 318810303
        folder = @folder.create( 'new_folder_created' )
        folder.root_id.should_not be_nil
      end
    end
    
  end

  describe RubyBox::UserAPI do
    describe '#list' do
      it "returns list of items in the folder path passed in" do
        response = @user_api.list('/MyDocs')
        response["total_count"].should eq(3)
        response["entries"].should include({"type"=>"folder", "id"=>"318810323", "sequence_id"=>"0", "name"=>"cool stuff"})
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
      it "should upload a new file to the specified folder path" do
        utf8_file_name = 'кузнецкий_105_а_№2.test'
        fdata = File.open( 'spec/'+utf8_file_name, 'rb' )
        response = @user_api.put_data( fdata, '/MyDocs/cool stuff', utf8_file_name)
        fdata = File.open( 'spec/'+utf8_file_name, 'rb' )
        
        response = @user_api.put_data( fdata, '/MyDocs/cool stuff', utf8_file_name)
        response["total_count"].should eq(1)
        response["entries"].all? { |e| e["type"] != "error" }.should be_true
      end
      
      it "should upload a new file to the specified folder path" do
        utf8_file_name = 'кузнецкий_105_а_№2.test'
        fdata = File.open( 'spec/' + utf8_file_name, 'rb' )
        
        file_to_delete = @user_api.file( "/MyDocs/cool stuff/#{utf8_file_name}" )
        file_to_delete.delete
        
        response = @user_api.put_data( fdata, '/MyDocs/cool stuff', utf8_file_name)
        response["total_count"].should eq(1)
        response["entries"].all? { |e| e["type"] != "error" }.should be_true
      end
    end
  
    describe '#file' do
      it "finds the id of a file" do
        fitem = @user_api.file( '/MyDocs/2513582219_03fb9b67db_b.jpg' )
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
        last_fitem = @user_api.folder('/MyDocs/cool stuff/екузц/path1/path2')
        last_fitem.delete
        
        
        response = @user_api.create_path('/MyDocs/cool stuff/екузц/path1/path2')
        response.root_id.should_not be_nil
      end
    end
    
    describe '#download' do
      it "finds the id of a file" do
        data = @user_api.download( '/MyDocs/cool stuff/кузнецкий_105_а_№2.test' )
        data.should eq "Test more data"
      end
      
      it "returns nil for a nonexistent file" do
        data = @user_api.download( '/MyDocs/doesntexist' )
        data.should eq nil
      end   
    end
  end
  
end

