module RubyBox
  class Folder < Item

    has_many :discussions
    has_many_paginated :items

    def files(name=nil, item_limit=100, offset=0)
      items(item_limit, offset).select do |item|
        item.kind_of? RubyBox::File and (name.nil? or item.name == name)
      end
    end

    def folders(name=nil, item_limit=100, offset=0)
      items(item_limit, offset).select do |item|
        item.kind_of? RubyBox::Folder and (name.nil? or item.name == name)
      end
    end

    def collaborations(item_limit=100, offset=0)
      items(item_limit, offset).select do |item|
        item.kind_of? RubyBox::Collaboration
      end
    end

    def upload_file(filename, data)
      file = RubyBox::File.new(@session, {
        'name' => filename,
        'parent' => RubyBox::User.new(@session, {'id' => id})
      })

      begin
        resp = file.upload_content(data) #write a new file. If there is a conflict, update the conflicted file.
      rescue RubyBox::ItemNameInUse => e
        file = RubyBox::File.new(@session, {
          'id' => e['context_info']['conflicts'][0]['id']
        })
        data.rewind
        resp = file.update_content( data )
      end
    end

    def create_subfolder(name)
      url = "#{RubyBox::API_URL}/#{resource_name}"
      uri = URI.parse(url)
      request = Net::HTTP::Post.new( uri.request_uri )
      request.body = JSON.dump({ "name" => name, "parent" => {"id" => id} })
      resp = @session.request(uri, request)
      RubyBox::Folder.new(@session, resp)
    end

    private

    def resource_name
      'folders'
    end

    def update_fields
      ['name', 'description']
    end
  end
end