#encoding: UTF-8

require 'spec_helper'
require 'helper/account'
require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::File do

  before do
    @session = RubyBox::Session.new
    @full_file = JSON.parse('{   "type": "file",    "id": "5000948880",    "sequence_id": "3",    "etag": "3",    "sha1": "134b65991ed521fcfe4724b7d814ab8ded5185dc",    "name": "tigers.jpeg",    "description": "a picture of tigers",    "size": 629644,    "path_collection": {        "total_count": 2,        "entries": [            {                "type": "folder",                "id": "0",                "sequence_id": null,                "etag": null,                "name": "All Files"            },            {                "type": "folder",                "id": "11446498",                "sequence_id": "1",                "etag": "1",                "name": "Pictures"            }        ]    },    "created_at": "2012-12-12T10:55:30-08:00",    "modified_at": "2012-12-12T11:04:26-08:00",    "trashed_at": null,    "purged_at": null,    "content_created_at": "2013-02-04T16:57:52-08:00",    "content_modified_at": "2013-02-04T16:57:52-08:00",    "created_by": {        "type": "user",        "id": "17738362",        "name": "sean rose",        "login": "sean@box.com"    },    "modified_by": {        "type": "user",        "id": "17738362",        "name": "sean rose",        "login": "sean@box.com"    },    "owned_by": {        "type": "user",        "id": "17738362",        "name": "sean rose",        "login": "sean@box.com"    },    "shared_link": {        "url": "https://www.box.com/s/rh935iit6ewrmw0unyul",        "download_url": "https://www.box.com/shared/static/rh935iit6ewrmw0unyul.jpeg",        "vanity_url": null,        "is_password_enabled": false,        "unshared_at": null,        "download_count": 0,        "preview_count": 0,        "access": "open",        "permissions": {            "can_download": true,            "can_preview": true        }    },    "parent": {        "type": "folder",        "id": "11446498",        "sequence_id": "1",        "etag": "1",        "name": "Pictures"    },    "item_status": "active"}')
    @mini_file = JSON.parse('{    "sequence_id": "0",    "type": "file",    "id": "2631999573",    "name":"IMG_1312.JPG"}')
    @comments = JSON.parse('{    "total_count": 1,    "entries": [        {            "type": "comment",            "id": "191969",            "is_reply_comment": false,            "message": "These tigers are cool!",            "created_by": {                "type": "user",                "id": "17738362",                "name": "sean rose",                "login": "sean@box.com"            },            "created_at": "2012-12-12T11:25:01-08:00",            "item": {                "id": "5000948880",                "type": "file"            },            "modified_at": "2012-12-12T11:25:01-08:00"        }    ]}')
  end

  it "should use missing_method to expose files fields" do
    file = RubyBox::File.new(@session, @mini_file)
    file.id.should == '2631999573'
  end

  it "should load all meta information if reload_meta is called" do
    # request is called once when reload_meta is automatically executed.
    RubyBox::Session.any_instance.should_receive(:request).once.and_return(@full_file)
    session = RubyBox::Session.new

    file = RubyBox::File.new(session, @mini_file)
    file.size.should == 629644
  end

  describe '#parent' do
    it 'should return parent folder' do
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @full_file)
      file.parent.name.should == 'Pictures'
    end

    it 'should reload_meta data if necessary before loading parent' do
      RubyBox::Session.any_instance.stub(:request).and_return(@full_file)
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @mini_file)
      file.parent.name.should == 'Pictures'
    end
  end

  describe '#update' do
    it 'should update files raw_item hash if name or description changed' do
      RubyBox::Session.any_instance.stub(:request).and_return(@full_file)
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @mini_file)
      file.name = 'Funky Monkey.jpg'
      file.description = 'a new description'
      file.name.should == 'Funky Monkey.jpg'
      file.description.should == 'a new description'    
    end

    it 'should not update files raw_item hash for keys not in update_fields' do
      RubyBox::Session.any_instance.stub(:request).and_return(@full_file)
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @mini_file)
      file.id = '000'
      file.id.should == '2631999573'
    end

    it 'should make request with appropriate update hash when update called' do
      RubyBox::Session.any_instance.stub(:request) do |uri, request|
        data = JSON.parse(request.body)
        data['description'].should == 'a new description'
      end
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @full_file)
      file.description = 'a new description'
      file.update
    end
  end

  describe '#put_data' do
    it "should load full meta information if etag not present" do
      RubyBox::Session.any_instance.should_receive(:request).twice.and_return(@full_file)
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @mini_file)
      file.stub(:prepare_upload).and_return('fake data')
      file.update_content('data')
    end
  end

  describe '#comments' do
    it 'should return an array of comment objects' do
      RubyBox::Session.any_instance.stub(:request).and_return(@comments)
      session = RubyBox::Session.new
      file = RubyBox::File.new(session, @mini_file)
      file.comments.first.message.should == 'These tigers are cool!'
    end
  end

end