require 'uri'
require 'net/https'
require 'json'
require 'net/http/post/multipart'

module RubyBox
  
  class FItem
    attr_accessor :xport, :root_id
    
    def initialize( xport, root_id=0 )
      @xport = xport
      @root_id = root_id
    end
    
  end
  
  class FFile < FItem
    def delete
      url = "https://api.box.com/2.0/files/#{@root_id}"
      uri = URI.parse(url)
      request = Net::HTTP::Delete.new( uri.request_uri )
      raw = true
      resp = @xport.do_http( uri, request, raw )
    end
    
    def get_info
      url = "https://api.box.com/2.0/files/#{@root_id}"
      uri = URI.parse(url)
      request = Net::HTTP::Get.new( uri.request_uri )
      raw = true
      resp = @xport.do_http( uri, request, raw )
    end
    
    def get_etag
      url = "https://api.box.com/2.0/files/#{@root_id}"
      uri = URI.parse(url)
      request = Net::HTTP::Get.new( uri.request_uri )
      raw = true
      resp = @xport.do_http( uri, request )['etag']
    end
    
    def put_data( data, fname )
      url = "https://upload.box.com/api/2.0/files/#{@root_id}/content"
      uri = URI.parse(url)
      etag = get_etag
      
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(data, "application/pdf", fname),
        "folder_id" => @root_id
      }, {"if-match" => etag })
      @xport.do_http(uri, request)
    end
  end
  
  class FFolder < FItem
    # return a new fitem.  The fitem.root_id is nil if no file found. 
    #
    # returns nil if there are no entries.
    # 
    # throws exception if low level exception occurred
    #
    def file( name )  
      resp = list
      return nil if resp['entries'].nil?  
      file_id = nil
      resp["entries"].each do |item|
        next if item["type"] != "file"
        file_id = item["id"] if item["name"] == name
      end
      FFile.new( @xport, file_id )
    end
    
    def folder( name )
      resp = list
      return nil if resp['entries'].nil?
      file_id = nil
      resp["entries"].each do |item|
        next if item["type"] != "folder"
        file_id = item["id"] if item["name"] == name
      end
      FFolder.new( @xport, file_id )
    end
    
    def delete
      url = "https://api.box.com/2.0/folders/#{@root_id}"
      uri = URI.parse(url)
      request = Net::HTTP::Delete.new( uri.request_uri )
      raw = true
      resp = @xport.do_http( uri, request, raw )
    end
    
    def list
      url = "https://api.box.com/2.0/folders/#{@root_id}/items"
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri.request_uri)
      return @xport.do_http(uri, request)
    end      
        
    def create( folder_name )
      url = "https://api.box.com/2.0/folders"
      uri = URI.parse(url)
      request = Net::HTTP::Post.new( uri.request_uri )
      request.body = { "name" => folder_name, "parent" => {"id" => @root_id} }.to_json
      resp = @xport.do_http( uri, request )
      fid = resp["id"] if resp["name"] == folder_name
      FFolder.new( @xport, fid )
    end
    
    def put_new_file( fname )
      url = "https://upload.box.com/api/2.0/files/content"
      uri = URI.parse(url)
      File.open( fname ) do |file_stream|
        request = Net::HTTP::Post::Multipart.new(uri.path, {
          "filename" => UploadIO.new(file_stream, "application/text", file),
          "folder_id" => @root_id
        })
        @xport.do_http(uri, request)
      end
    end
    
    def put_new_file_data( data, fname )
      url = "https://upload.box.com/api/2.0/files/content"
      uri = URI.parse(url)
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(data, "application/pdf", fname),
        "folder_id" => @root_id
      })
      @xport.do_http(uri, request)
    end    
  end
  
  #user level - path inputs
  class UserAPI
    def initialize( xport )
      @xport = xport
      @folder = FFolder.new( @xport )
    end
    
    def list( path )
      fitem = folder( path )
      return {} if fitem.nil?
      return fitem.list
    end
    
    def put_data( data, path, file )
      fitem = create_path( path )
      begin
        resp = fitem.put_new_file_data(data, file) #write a new file. If there is a conflict, update the conflicted file.
      rescue RubyBox::ItemNameInUse => e
        file_fitem = file( path + '/' + file )
        data.rewind
        resp = file_fitem.put_data( data, file )
      end
      resp
    end
    
    def file( path )
      folders = path.split('/')
      fname = folders.pop
      while !folders.empty? && folders.first.empty?
        folders.shift
      end
      root_fitem = @folder
      folders.each do |folder|
        root_fitem = root_fitem.folder( folder )
        return nil if root_fitem.root_id.nil?
      end
      retval = root_fitem.file( fname )
      retval.nil? || retval.root_id.nil? ? nil : retval
    end

    def get_file_info( path )
      fitem = file( path )
      return nil if fitem.nil?
      JSON.parse( fitem.get_info )
    end
    
    def download( path )
      fitem = file( path )
      return nil if fitem.nil?
      # url = "https://api.box.com/2.0/files/#{fitem.root_id}/data" # bug: http://community.box.com/boxnet/topics/box_com_cant_down_file_used_api
      url = "https://www.box.com/api/1.0/download/#{@xport.auth_token}/#{fitem.root_id}"  #api v1.0 - this does work
      uri = URI.parse(url)
      request = Net::HTTP::Get.new( uri.request_uri )
      raw = true
      resp = @xport.do_http( uri, request, raw )
    end    
    
    def create_path( path )
      folders = path.split('/')
      while !folders.empty? && folders.first.empty?
        folders.shift
      end
      root_fitem = @folder
      folders.each do |folder|
        next_folder = root_fitem.folder( folder ) # find it
        unless next_folder.root_id 
          next_folder = root_fitem.create( folder )      # else create it
        end
        root_fitem = next_folder
      end
      root_fitem
    end
          
    def folder(path)
      return nil if path.nil?
      folders = path.split('/')
      while !folders.empty? && folders.first.empty?
        folders.shift
      end
      root_fitem = @folder
      
      folders.each do |folder|
        root_fitem = root_fitem.folder( folder )
        return nil if root_fitem.root_id.nil?
      end
      return root_fitem
    end
    
  end
  
  class Xport
    attr_accessor :api_key, :auth_token
    
    def initialize(api_key, auth_token)
      @api_key = api_key
      @auth_token = auth_token
    end
    # low level communication routines
    
    def build_auth_header
      "BoxAuth api_key=#{@api_key}&auth_token=#{@auth_token}"
    end
    
    def do_http(uri, request, raw=false)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.ssl_version = :SSLv3
      
      request.add_field('Authorization', build_auth_header)
      response = http.request(request)
      if response.is_a? Net::HTTPNotFound
        raise RubyBox::ObjectNotFound
      end
      handle_errors( response.code.to_i, response.body, raw )
      # raw ? response.body : handle_errors( response.body )
    end
    
    def handle_errors( status, body, raw )
      begin
        parsed_body = JSON.parse(body)
      rescue
        msg = body.nil? || body.empty? ? "no data returned" : body
        parsed_body = { "message" =>  msg }
      end
      
      case status / 100
      when 4
        raise(RubyBox::ItemNameInUse, parsed_body["message"]) if parsed_body["code"] == "item_name_in_use"
        raise(RubyBox::AuthError, parsed_body["message"]) if parsed_body["code"] == "unauthorized"
        raise(RubyBox::RequestError, parsed_body["message"])
      when 5
        raise RubyBox::ServerError, parsed_body["message"]
      end
      raw ? body : parsed_body
    end
  end
end
