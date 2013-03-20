require 'uri'
require 'net/https'
require 'json'
require 'net/http/post/multipart'
require 'open-uri'

module RubyBox
  class Client
    def initialize(session)
      @session = session
    end

    def root_folder
      folder = Folder.new(@session, {'id' => '0'})
      folder.reload_meta
      folder
    end
  end
end

=begin  
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
        file_fitem = nil
        begin
          file_fitem = FFile.new(@xport, e['context_info']['conflicts'][0]['id'])
        rescue # Fallback to looking up by filename if we don't receive an ID back from BOX.
          file_fitem = file( path + '/' + file )
        end
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
end
=end
