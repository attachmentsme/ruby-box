module RubyBox
  class File < Item

    def put_data( data, fname )
      @raw_item = reload_meta unless etag

      url = "#{RubyBox::UPLOAD_URL}/#{resource_name}/#{id}/content"
      uri = URI.parse(url)

      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => prepare_upload(data, fname),
        "folder_id" => id
      }, {"if-match" => etag })

      @session.request(uri, request)
    end

    def download
  #    # url = "https://api.box.com/2.0/files/#{fitem.root_id}/data" # bug: http://community.box.com/boxnet/topics/box_com_cant_down_file_used_api
  #    url = "https://www.box.com/api/1.0/download/#{@session.auth_token}/#{id}"  #api v1.0 - this does work
  #    uri = URI.parse(url)
  #    request = Net::HTTP::Get.new( uri.request_uri )
  #    raw = true
  #    resp = @xport.do_http( uri, request, raw )
    end

    def stream( path, opts={} )
   #   fitem = file( path )
   #   return nil if fitem.nil?
   #   # url = "https://api.box.com/2.0/files/#{fitem.root_id}/data" # bug: http://community.box.com/boxnet/topics/box_com_cant_down_file_used_api
   #   url = "https://www.box.com/api/1.0/download/#{@xport.auth_token}/#{fitem.root_id}"  #api v1.0 - this does work
   #   @xport.do_stream( url, opts )
    end

    def comments
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/comments"
      resp = @session.get( url )
      resp['entries'].map {|i| Comment.new(@session, i)}
    end

    private

    def resource_name
      'files'
    end

    def update_fields
      ['name', 'description']
    end

    def prepare_upload(data, fname)
      UploadIO.new(data, "application/pdf", fname)
    end

  end
end