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

    # make sure status and body is
    # set on error object.
    begin
      @client.root_folder
    rescue Exception => e
      e.body.should == '{"type": "error", "status": 401, "message": "baddd req"}'
      e.status.should == 401
    end
  end

  it "raises a ServerError if the server raises a 500 error" do
    stub_request(:get, "https://api.box.com/2.0/folders/0").to_return(:status => 503, :body => '{"type": "error", "status": 503, "message": "We messed up! - Box.com"}', :headers => {})
    lambda {@client.root_folder}.should raise_error( RubyBox::ServerError )
    
    # make sure status and body is
    # set on error object.
    begin
      @client.root_folder
    rescue Exception => e
      e.body.should == '{"type": "error", "status": 503, "message": "We messed up! - Box.com"}'
      e.status.should == 503
    end

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

    describe '#files' do
      it "allows additional fields to be requested in file listing" do
        folder = RubyBox::Folder.new(@session, {'id' => '318810303'})
        file = folder.files({fields: [:name, :size]}).first
        file.id.should == "2550686921"
        file.name.should == "2513582219_03fb9b67db_b.jpg"
        file.size.should == 593978
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

    describe RubyBox::Client do
      describe '#item' do
        it "item method can lookup generic items, e.g., files or folders" do
          file = @client.item( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
          file.size.should == 14
          file.name.should == 'кузнецкий_105_а_№2.test'

          folder = @client.item( 'ruby-box_gem_testing' )
          folder.name.should == 'ruby-box_gem_testing'
        end
      end
    end

    context 'uploading files' do
      it "should update an existing file" do
        utf8_file_name = '遠志教授.jpg'
        fdata = File.open( 'spec/fixtures/' + utf8_file_name, 'rb' )
        response = @client.upload_data('/ruby-box_gem_testing/cool stuff/遠志教授.jpg', fdata)
        fdata = File.open( 'spec/fixtures/' + utf8_file_name, 'rb' )
        
        file = @client.upload_data('/ruby-box_gem_testing/cool stuff/遠志教授.jpg', fdata)
        file.name.should == '遠志教授.jpg'
        file.delete
      end

      it 'should raise an exception if files collide and overwrite is false' do
        fdata = File.open( 'spec/fixtures/遠志教授.jpg', 'rb' )
        file = @client.upload_data('/ruby-box_gem_testing/cool stuff/遠志教授.jpg', fdata)
        fdata = File.open( 'spec/fixtures/遠志教授.jpg', 'rb' )
        
        expect{ @client.upload_data('/ruby-box_gem_testing/cool stuff/遠志教授.jpg', fdata, false) }.to raise_error(RubyBox::ItemNameInUse)
        file.delete
      end
      
      it "should upload a new file" do
        utf8_file_name = '遠志教授.jpg'
        file = @client.upload_file('spec/fixtures/' + utf8_file_name, '/ruby-box_gem_testing/cool stuff/')
        file.name.should == '遠志教授.jpg'
        file.delete        
      end

      it "should allow a file to be uploaded by a folder id" do
        utf8_file_name = '遠志教授.jpg'
        folder = @client.folder('/ruby-box_gem_testing/cool stuff/')
        file = @client.upload_file_by_folder_id('spec/fixtures/' + utf8_file_name, folder.id)
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

    describe '#folder_by_id' do
      it "allows a folder to be retrieved by its id" do
        folder = @client.folder('/ruby-box_gem_testing')
        folder_by_id = @client.folder_by_id(folder.id)
        folder_by_id.name.should == folder.name
      end
    end

    describe '#delete folder' do
      it "should be able to recursively delete the contents of a folder" do
        folder = @client.create_folder('/ruby-box_gem_testing/delete_test')
        @client.create_folder('/ruby-box_gem_testing/delete_test/subfolder')
        folder.delete(recursive: 'true')
      end
    end

    context 'retrieving a file' do
      it "returns meta information for a file" do
        file = @client.file( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        file.size.should == 14
      end

      it "a file can be retrieved by its id" do
        file = @client.file( '/ruby-box_gem_testing/cool stuff/кузнецкий_105_а_№2.test' )
        file_by_id = @client.file_by_id( file.id )
        file_by_id.size.should == 14
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

    describe '#collaborations' do
      it 'should be able to create and list collaborations on a folder' do
        folder = @client.create_folder('/ruby-box_gem_testing/collaboration_folder')
        folder.create_collaboration('bencoe@gmail.com')
        folder.create_collaboration('ben@attachments.me', 'editor')
        collaborations = folder.collaborations.to_a

        collaborations[0].role.should == 'viewer'
        collaborations[1].role.should == 'editor'
        collaborations.count.should == 2

        folder.delete if folder
      end
    end

    describe '#shared_link' do
      it 'should allow a share link to be created for a folder' do
        folder = @client.create_folder('/ruby-box_gem_testing/shared_folder').create_shared_link

        # share link was successfully created.
        folder.shared_link.url.should match /https?:\/\/[\S]+/
        folder.shared_link.is_a?(RubyBox::SharedLink).should == true

        # share link can be disabled.
        folder.disable_shared_link
        folder.shared_link.should == nil

        folder.delete if folder
      end

      it 'should allow a share link to be created for a file' do
        utf8_file_name = '遠志教授.jpg'
        file = @client.upload_file('spec/fixtures/' + utf8_file_name, '/ruby-box_gem_testing/cool stuff/').create_shared_link

        # share link was successfully created.
        file.shared_link.url.should match /https?:\/\/[\S]+/
        
        # share link can be disabled.
        file.disable_shared_link
        file.shared_link.should == nil

        file.delete        
      end
    end

    describe "#create_comment" do
      it "allows a comment to be created on a file" do
        file = @client.upload_file('spec/fixtures/遠志教授.jpg', '/ruby-box_gem_testing/cool stuff/')
        file.create_comment('Hello world!')
        file.comments.first.message.should == 'Hello world!'
        file.delete
      end
    end

    describe "#copy_to" do
      it "it copies a file to a folder when a folder id is passed in" do
        file = @client.upload_file('spec/fixtures/遠志教授.jpg', '/ruby-box_gem_testing/')
        folder = @client.folder('/ruby-box_gem_testing/cool stuff/')
        
        file.copy_to(folder.id)

        copied_file = @client.file('/ruby-box_gem_testing/cool stuff/遠志教授.jpg')

        copied_file.name.should == file.name
        copied_file.size.should == file.size

        file.delete
        copied_file.delete
      end

      it "it copies a file to a folder when a folder is passed in" do
        file = @client.upload_file('spec/fixtures/遠志教授.jpg', '/ruby-box_gem_testing/')
        folder = @client.folder('/ruby-box_gem_testing/cool stuff/')
        
        file.copy_to(folder)

        copied_file = @client.file('/ruby-box_gem_testing/cool stuff/遠志教授.jpg')

        copied_file.name.should == file.name
        copied_file.size.should == file.size

        file.delete
        copied_file.delete
      end

      it "allows file to be renamed when copied" do
        file = @client.upload_file('spec/fixtures/遠志教授.jpg', '/ruby-box_gem_testing/')
        folder = @client.folder('/ruby-box_gem_testing/cool stuff/')
        
        file.copy_to(folder, 'banana.jpg')

        copied_file = @client.file('/ruby-box_gem_testing/cool stuff/banana.jpg')

        copied_file.name.should == 'banana.jpg'
        copied_file.size.should == file.size

        file.delete
        copied_file.delete
      end
    end

    describe "#move_to" do
      it "it moves a file to a folder, the original no longer exists" do
        file = @client.upload_file('spec/fixtures/遠志教授.jpg', '/ruby-box_gem_testing/')
        folder = @client.folder('/ruby-box_gem_testing/cool stuff/')

        file.move_to(folder.id)
        original_file = @client.file('/ruby-box_gem_testing/遠志教授.jpg')
        original_file.should == nil # the original should no longer exist.

        moved_file = @client.file('/ruby-box_gem_testing/cool stuff/遠志教授.jpg')
        moved_file.name.should == file.name # the file should exist in the new location.
        moved_file.size.should == file.size

        moved_file.delete
      end

      it "allows file to be renamed when moved" do
        file = @client.upload_file('spec/fixtures/遠志教授.jpg', '/ruby-box_gem_testing/')
        folder = @client.folder('/ruby-box_gem_testing/cool stuff/')

        file.move_to(folder, 'banana.jpg')
        original_file = @client.file('/ruby-box_gem_testing/遠志教授.jpg')
        original_file.should == nil # the original should no longer exist.

        moved_file = @client.file('/ruby-box_gem_testing/cool stuff/banana.jpg')
        moved_file.name.should == 'banana.jpg' # the file should exist in the new location.
        moved_file.size.should == file.size

        moved_file.delete
      end

    end

  end
end
