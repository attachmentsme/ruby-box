module RubyBox
  class File < Item

    def download
      resp = stream.read
    end

    def stream( opts={} )
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/content"
      @session.do_stream( url, opts )
    end

    def comments
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/comments"
      resp = @session.get( url )
      resp['entries'].map {|i| Comment.new(@session, i)}
    end

    def upload_content( path )
      url = "#{RubyBox::UPLOAD_URL}/#{resource_name}/content"
      uri = URI.parse(url)
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(data, "application/pdf", name),
        "folder_id" => parent.id
      })
      @raw_item = @session.request(uri, request)
      self
    end

    def update_content( path )

      url = "#{RubyBox::UPLOAD_URL}/#{resource_name}/#{id}/content"
      uri = URI.parse(url)

      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => prepare_upload(data, name),
        "folder_id" => parent.id
      }, {"if-match" => etag })

      @raw_item = @session.request(uri, request)
      self
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