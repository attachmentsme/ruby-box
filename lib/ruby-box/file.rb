module RubyBox
  class File < Item

    def download
      #url = "https://api.box.com/2.0/#{resource_name}/#{id}/content" # bug: http://community.box.com/boxnet/topics/box_com_cant_down_file_used_api
      url = "#{LEGACY_DOWNLOAD_URL}//#{@session.auth_token}/#{id}"  #api v1.0 - this does work
      uri = URI.parse(url)
      request = Net::HTTP::Get.new( uri.request_uri )
      raw = true
      resp = @session.request( uri, request, raw )
    end

    def stream( opts={} )
      url = "#{LEGACY_DOWNLOAD_URL}/#{@session.auth_token}/#{id}"  #api v1.0 - this does work
      @session.do_stream( url, opts )
    end

    def parent
      @raw_item = reload_meta unless @raw_item['parent']
      @parent = RubyBox::Folder.new(@session, @raw_item['parent']) unless @parent
      @parent
    end

    def comments
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/comments"
      resp = @session.get( url )
      resp['entries'].map {|i| Comment.new(@session, i)}
    end

    def upload_content( data )
      url = "https://upload.box.com/api/2.0/#{resource_name}/content"
      uri = URI.parse(url)
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(data, "application/pdf", name),
        "folder_id" => parent.id
      })
      @session.request(uri, request)
    end

    def update_content( data )
      @raw_item = reload_meta unless etag

      url = "#{RubyBox::UPLOAD_URL}/#{resource_name}/#{id}/content"
      uri = URI.parse(url)

      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => prepare_upload(data, name),
        "folder_id" => parent.id
      }, {"if-match" => etag })

      @session.request(uri, request)
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