#encoding: UTF-8

require 'helper/account'
require 'ruby-box'

describe RubyBox, '#list' do
  it "returns list of items in the root folder if no arguments given" do
    ruby_box = RubyBox.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    response = ruby_box.list
    response["total_count"].should eq(12)
    response["entries"].should include({"type"=>"folder","id"=>"207491015","sequence_id"=>"0","name"=>"attachments"})
  end
  
  it "returns list of items in the folder id passed in" do
    ruby_box = RubyBox.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    response = ruby_box.list(207491015)
    response["total_count"].should eq(3)
    response["entries"].should include({"type"=>"file", "id"=>"1600119854", "sequence_id"=>"0", "name"=>"a_atme_chrome_notes_01.pdf"})
  end
end

describe RubyBox, '#list_by_path' do
  it "returns list of items in the folder path passed in" do
    ruby_box = RubyBox.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    response = ruby_box.list_by_path('/testing/testing')
    response["total_count"].should eq(3)
    response["entries"].should include({"type"=>"file", "id"=>"2260637039", "sequence_id"=>"0", "name"=>"another"})
  end
end

describe RubyBox, '#put_file' do
  it "should upload a file to box" do
    ruby_box = RubyBox.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    utf8_file_name = 'spec/кузнецкий_105_а_№2.test'
    response = ruby_box.put_file(285367865, File.new(utf8_file_name))
    response["total_count"].should eq(1)
  end

  it "should upload a file to box with just the path" do
    ruby_box = RubyBox.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    utf8_file_name = 'spec/кузнецкий_105_а_№2.test'
    response = ruby_box.put_file(285367865, utf8_file_name)
    response["total_count"].should eq(1)
  end
end

describe RubyBox, '#put_file_in_folder_path' do
  it "should upload a file to the specified folder path" do
    ruby_box = RubyBox.new(ACCOUNT['api_key'], ACCOUNT['auth_token'])
    utf8_file_name = 'spec/кузнецкий_105_а_№2.test'
    response = ruby_box.put_file_in_folder_path('/testing', utf8_file_name)
    response["total_count"].should eq(1)
  end
end
