module RubyBox
  class File < Item

    def delete
      url = "#{RubyBox::API_URL}/files/#{@root_id}"
      raw = true
      resp = @session.delete( url, raw )
    end
    
    def get_info
      url = "#{RubyBox::API_URL}/files/#{@root_id}"
      raw = true
      resp = @session.get( url, raw )
    end
    
    def get_etag
      url = "#{RubyBox::API_URL}/files/#{@root_id}"
      uri = URI.parse(url)
      request = Net::HTTP::Get.new( uri.request_uri )
      raw = true
      resp = @xport.do_http( uri, request )['etag']
    end
    
    def put_data( data, fname )
      url = "#{RubyBox::UPLOAD_URL}/files/#{@root_id}/content"
      etag = get_etag
      uri = URI.parse(url)
      
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(data, "application/pdf", fname),
        "folder_id" => @root_id
      }, {"if-match" => etag })

      @session.request(uri, request)
    end
  end
end