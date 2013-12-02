module RubyBox
  class File < Item

    has_many :comments

    def download
      resp = stream.read
    end

    def download_url
      @session.get( file_content_url )["location"]
    end

    def copy_to( folder_id, name=nil )

      # Allow either a folder_id or a folder object
      # to be passed in.
      folder_id = folder_id.id if folder_id.instance_of?(RubyBox::Folder)

      uri = URI.parse( "#{RubyBox::API_URL}/#{resource_name}/#{id}/copy" )
      request = Net::HTTP::Post.new( uri.request_uri )
      request.body = JSON.dump({
        "parent" => {"id" => folder_id},
        "name" => name
      })

      resp = @session.request(uri, request)
    end

    def stream( opts={} )
      open(download_url, opts)
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

    def create_comment(message)
      RubyBox::Comment.new(@session, {
          'item' => {'id' => id, 'type' => type},
          'message' => message
      }).create
    end

    private
    def file_content_url
      "#{RubyBox::API_URL}/#{resource_name}/#{id}/content"
    end
    

    def resource_name
      'files'
    end

    def has_mini_format?
      true
    end

    def prepare_upload(data, fname)
      UploadIO.new(data, "application/pdf", fname)
    end

  end
end
