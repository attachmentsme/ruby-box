module RubyBox
  class File < Item

    def delete
      url = "#{RubyBox::API_URL}/files/#{id}"
      resp = @session.delete( url )
    end
    
    def update_meta
      url = "#{RubyBox::API_URL}/files/#{id}"
      @raw_item = @session.get( url )
    end

    def put_data( data, fname )
      @raw_item = update_meta unless etag

      url = "#{RubyBox::UPLOAD_URL}/files/#{id}/content"
      uri = URI.parse(url)

      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => prepare_upload(data, fname),
        "folder_id" => id
      }, {"if-match" => etag })

      @session.request(uri, request)
    end

    private

    def prepare_upload(data, fname)
      UploadIO.new(data, "application/pdf", fname)
    end

  end
end