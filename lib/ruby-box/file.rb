module RubyBox
  class File < Item

    has_many :comments

    def download
      resp = stream.read
    end

    def stream( opts={} )
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/content"
      @session.do_stream( url, opts )
    end

    def upload_content( data )
      url = "#{RubyBox::UPLOAD_URL}/#{resource_name}/content"
      uri = URI.parse(url)
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(data, "application/pdf", name),
        "folder_id" => parent.id
      })

      resp = @session.request(uri, request)
      if resp['entries']
        @raw_item = resp['entries'][0]
      else
        @raw_item = resp
      end
      self
    end

    def update_content( data )

      url = "#{RubyBox::UPLOAD_URL}/#{resource_name}/#{id}/content"
      uri = URI.parse(url)

      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => prepare_upload(data, name),
        "folder_id" => parent.id
      }, {"if-match" => etag })

      resp = @session.request(uri, request)
      if resp['entries']
        @raw_item = resp['entries'][0]
      else
        @raw_item = resp
      end
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