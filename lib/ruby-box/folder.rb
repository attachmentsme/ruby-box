module RubyBox
  class Folder < Item

    has_many :discussions
    has_many :collaborations
    has_many_paginated :items

    def files(name=nil, item_limit=100, offset=0, fields=nil)
      items_by_type(RubyBox::File, name, item_limit, offset, fields)
    end

    def folders(name=nil, item_limit=100, offset=0, fields=nil)
      items_by_type(RubyBox::Folder, name, item_limit, offset, fields)
    end

    def upload_file(filename, data, overwrite=true)
      file = RubyBox::File.new(@session, {
        'name' => filename,
        'parent' => RubyBox::Folder.new(@session, {'id' => id})
      })

      begin
        resp = file.upload_content(data) #write a new file. If there is a conflict, update the conflicted file.
      rescue RubyBox::ItemNameInUse => e
        
        # if overwrite flag is false, simply raise exception.
        raise e unless overwrite

        # otherwise let's attempt to overwrite the file.
        data.rewind

        # The Box API occasionally does not return
        # context info for an ItemNameInUse exception.
        # This is a workaround around:
        begin
          # were were given context information about this conflict?
          file = RubyBox::File.new(@session, {
            'id' => e['context_info']['conflicts'][0]['id']
          })
        rescue
          # we were not given context information about this conflict.
          # attempt to lookup the file.
          file = files(filename, 1000).pop
        end

        raise e unless file # re-raise the ItemNameInUse exception.
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

    # see http://developers.box.com/docs/#collaborations-collaboration-object
    # for a list of valid roles.
    def create_collaboration(email, role=:viewer)
      RubyBox::Collaboration.new(@session, {
          'item' => {'id' => id, 'type' => type},
          'accessible_by' => {'login' => email},
          'role' => role.to_s
      }).create
    end

    # see http://developers.box.com/docs/#folders-copy-a-folder
    # for a description of the behavior
    def copy_to(destination, name=nil)
      parent = {'parent' => {'id' => destination.id}}
      parent.merge!('name' => name) if name

      RubyBox::Folder.new(@session, post(folder_method(:copy), parent))
    end

    private
    def post(extra_url, body)
      uri = URI.parse("#{RubyBox::API_URL}/#{extra_url}")
      post = Net::HTTP::Post.new(uri.request_uri)
      post.body = JSON.dump(body)
      @session.request(uri, post)
    end

    def resource_name
      'folders'
    end

    def folder_method(method)
      "folders/#{id}/#{method}"
    end

    def has_mini_format?
      true
    end

    def items_by_type(type, name, item_limit, offset, fields)

      # allow paramters to be set via
      # a hash rather than a list of arguments.
      if name.is_a?(Hash)
        return items_by_type(type, name[:name], name[:item_limit], name[:offset], name[:fields])
      end

      items(item_limit, offset, fields).select do |item|
        item.kind_of? type and (name.nil? or item.name.casecmp(name) == 0)
      end

    end
  end
end
