#encoding: UTF-8

require 'spec_helper'
require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::Folder do
  before do
    @session = RubyBox::Session.new
    @full_folder = JSON.parse('{    "type": "folder",    "id": "11446498",    "sequence_id": "1",    "etag": "1",    "name": "Pictures",    "created_at": "2012-12-12T10:53:43-08:00",    "modified_at": "2012-12-12T11:15:04-08:00",    "description": "Some pictures I took",    "size": 629644,    "path_collection": {        "total_count": 1,        "entries": [            {                "type": "folder",                "id": "0",                "sequence_id": null,                "etag": null,                "name": "All Files"            }        ]    },    "created_by": {        "type": "user",        "id": "17738362",        "name": "sean rose",        "login": "sean@box.com"    },    "modified_by": {        "type": "user",        "id": "17738362",        "name": "sean rose",        "login": "sean@box.com"    },    "owned_by": {        "type": "user",        "id": "17738362",        "name": "sean rose",        "login": "sean@box.com"    },    "shared_link": {        "url": "https://www.box.com/s/vspke7y05sb214wjokpk",        "download_url": "https://www.box.com/shared/static/vspke7y05sb214wjokpk",        "vanity_url": null,        "is_password_enabled": false,        "unshared_at": null,        "download_count": 0,        "preview_count": 0,        "access": "open",        "permissions": {            "can_download": true,            "can_preview": true        }    },    "folder_upload_email": {        "access": "open",        "email": "upload.Picture.k13sdz1@u.box.com"    },    "parent": {        "type": "folder",        "id": "0",        "sequence_id": null,        "etag": null,        "name": "All Files"    },    "item_status": "active",    "item_collection": {        "total_count": 1,        "entries": [            {                "type": "file",                "id": "5000948880",                "sequence_id": "3",                "etag": "3",                "sha1": "134b65991ed521fcfe4724b7d814ab8ded5185dc",                "name": "tigers.jpeg"            }        ],        "offset": 0,        "limit": 100    }}')
    @mini_folder = JSON.parse('{    "type":"folder",    "id":"301415432",    "sequence_id":"0",    "name":"my first sub-folder"}')
    @items = [
      JSON.parse('{    "total_count": 4,    "entries": [        {            "type": "folder",            "id": "409047867",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s your folder"        },        {            "type": "file",            "id": "409042867",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        },    { "type": "collaboration", "id": "409042000", "status": "accepted" } ],    "offset": "0",    "limit": "3"}'),
      JSON.parse('{    "total_count": 4,    "entries": [        {            "type": "folder",            "id": "409047868",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s another folder"        },        {            "type": "file",            "id": "409042810",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        },    { "type": "collaboration", "id": "409042001", "status": "accepted" }   ],    "offset": "2",    "limit": "3"}')
    ]
  end

  it "#root returns full root folder object" do
    RubyBox::Session.any_instance.stub(:request).and_return(@full_folder)
    session = RubyBox::Session.new
    root = RubyBox::Client.new(session).root_folder
    root.name.should == 'Pictures'
  end

  it "returns iso8601 format keys as a time object" do
    RubyBox::Session.any_instance.stub(:request).and_return(@full_folder)
    session = RubyBox::Session.new
    root = RubyBox::Client.new(session).root_folder
    root.created_at.year.should == 2012
  end

  describe '#items' do
    it "should return a folder object for folder items" do
      item = JSON.parse('{    "id": "0000001", "total_count": 1,    "entries": [        {            "type": "folder",            "id": "409047867",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s your folder"        }   ],    "offset": "0",    "limit": "1"}')
      RubyBox::Session.any_instance.stub(:request).and_return(item)
      session = RubyBox::Session.new
      item = RubyBox::Client.new(session).root_folder.items.first
      item.kind_of?(RubyBox::Folder).should == true
    end

    it "should return a file object for file items" do
      item = JSON.parse('{    "id": "0000001", "total_count": 1,    "entries": [ {            "type": "file",            "id": "409042867",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        }   ],    "offset": "0",    "limit": "1"}')
      RubyBox::Session.any_instance.stub(:request).and_return(item)
      session = RubyBox::Session.new
      item = RubyBox::Client.new(session).root_folder.items.first
      item.kind_of?(RubyBox::File).should == true
    end

    it "it should return an iterator that lazy loads all entries" do
      RubyBox::Session.any_instance.stub(:request) { @items.pop }
      session = RubyBox::Session.new
      items = RubyBox::Folder.new(session, {'id' => 1}).items(1).to_a
      items[0].kind_of?(RubyBox::Folder).should == true
      items[1].kind_of?(RubyBox::File).should == true
    end
  end

  describe '#files' do
    it "should only return items of type file" do
      RubyBox::Session.any_instance.stub(:request) { @items.pop }
      session = RubyBox::Session.new
      files = RubyBox::Folder.new(session, {'id' => 1}).files
      files.count.should == 1
      files.first.kind_of?(RubyBox::File).should == true
    end

    it "should allow you to filter files by name" do
      items = [
        JSON.parse('{    "total_count": 4,    "entries": [        {            "type": "folder",            "id": "409047867",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s your folder"        },        {            "type": "file",            "id": "409042867",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        }    ],    "offset": "0",    "limit": "2"}'),
        JSON.parse('{    "total_count": 4,    "entries": [        {            "type": "folder",            "id": "409047868",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s another folder"        },        {            "type": "file",            "id": "409042810",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        }    ],    "offset": "2",    "limit": "2"}')  
      ]

      RubyBox::Session.any_instance.stub(:request) { items.pop }
      session = RubyBox::Session.new

      # should return one file.
      files = RubyBox::Folder.new(session, {'id' => 1}).files('A choice file')
      files.count.should == 1

      items = [
        JSON.parse('{    "total_count": 4,    "entries": [        {            "type": "folder",            "id": "409047867",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s your folder"        },        {            "type": "file",            "id": "409042867",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        }    ],    "offset": "0",    "limit": "2"}'),
        JSON.parse('{    "total_count": 4,    "entries": [        {            "type": "folder",            "id": "409047868",            "sequence_id": "1",            "etag": "1",            "name": "Here\'s another folder"        },        {            "type": "file",            "id": "409042810",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        }    ],    "offset": "2",    "limit": "2"}')  
      ]

      # should return no files.
      files = RubyBox::Folder.new(session, {'id' => 1}).files('foobar')
      files.count.should == 0
    end

  end

  describe '#discussions' do
    it "should return all the discussions surrounding a folder" do
      item = JSON.parse('{    "id": "0000001", "total_count": 1,    "entries": [ {            "type": "discussion",            "id": "409042867",            "sequence_id": "1",            "etag": "1",            "name": "A choice file"        }   ],    "offset": "0",    "limit": "1"}')
      RubyBox::Session.any_instance.stub(:request).and_return(item)
      session = RubyBox::Session.new
      item = RubyBox::Client.new(session).root_folder.discussions.first
      item.kind_of?(RubyBox::Discussion).should == true
    end
  end

  describe '#folders' do
    it "should only return items of type folder" do
      RubyBox::Session.any_instance.stub(:request) { @items.pop }
      session = RubyBox::Session.new
      files = RubyBox::Folder.new(session, {'id' => 1}).folders
      files.count.should == 1
      files.first.kind_of?(RubyBox::Folder).should == true
    end
  end

  describe '#collaborations' do
    it "should only return items of type Collaboration" do
      RubyBox::Session.any_instance.stub(:request) { @items.pop }
      session = RubyBox::Session.new
      collaborations = RubyBox::Folder.new(session, {'id' => 1}).collaborations
      collaborations.count.should == 1
      collaborations.first.kind_of?(RubyBox::Collaboration).should == true
    end
  end
end
