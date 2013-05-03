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
    end

    def folder(path='/')
      path = path.sub(/(^\.$)|(^\.\/)/, '') if path # handle folders with leading '.'
      return root_folder if ['', '/'].member?(path)
      folder_from_split_path( split_path(path) )
    end

    def file(path)
      path = split_path( path.sub(/^\.\//, '') )
      file_name = path.pop
      folder = folder_from_split_path( path )
      folder.files(file_name).first if folder
    end

    def download(path)
      file = file(path)
      file.download if file
    end

    def stream(path, opts={})
      file = file(path)
      file.stream(opts) if file
    end

    def search(query, item_limit=100, offset=0)
      Enumerator.new do |yielder|
        while true
          url = "#{RubyBox::API_URL}/search?query=#{URI::encode(query)}&limit=#{item_limit}&offset=#{offset}"
          resp = @session.get( url )
          resp['entries'].each do |entry|
            yielder.yield(RubyBox::Item.factory(@session, entry))
          end
          offset += resp['entries'].count
          break if resp['offset'].to_i + resp['limit'].to_i >= resp['total_count'].to_i
        end
      end
    end

    def create_folder(path)
      folder = root_folder
      folder_names = split_path(path)
      folder_names.each do |folder_name|
        new_folder = folder.folders(folder_name).first        
        if !new_folder
          begin
            new_folder = folder.create_subfolder(folder_name)
          rescue RubyBox::ItemNameInUse => e
            new_folder = folder.folders(folder_name).first
          end
        end
        folder = new_folder
      end
      folder
    end

    def upload_data(path, data)
      path = split_path(path)
      file_name = path.pop
      folder = create_folder(path.join('/'))
      folder.upload_file(file_name, data) if folder
    end

    def upload_file(local_path, remote_path)
      file_name = local_path.split('/').pop
      folder = create_folder( remote_path )
      return unless folder
      ::File.open( local_path ) do |data|
        folder.upload_file(file_name, data)
      end
    end

    def split_path(path)
      path.gsub!(/(^\/)|(\/$)/, '')
      path.split('/')
    end

    def event_response(stream_position=0, stream_type=:all, limit=100)
      q = fmt_events_args stream_position, stream_type, limit
      url = "#{RubyBox::API_URL}/events?#{q}"
      resp = @session.get( url )
      EventResponse.new(@session, resp)
    end

    def me
      resp = @session.get( "#{RubyBox::API_URL}/users/me" )
      User.new(@session, resp)
    end

    private

    def folder_from_split_path(path)
      folder = root_folder
      path.each do |folder_name|
        folder = folder.folders(folder_name).first
        return nil unless folder
      end
      folder
    end

    def fmt_events_args(stream_position, stream_type, limit)
      unless stream_position.to_s == 'now'
        stream_position = stream_position.kind_of?(Numeric) ? stream_position : 0
      end
      stream_type = [:all, :changes, :sync].include?(stream_type) ? stream_type : :all
      limit = limit.kind_of?(Fixnum) ? limit : 100
      "stream_position=#{stream_position}&stream_type=#{stream_type}&limit=#{limit}"
    end
    
  end
end
