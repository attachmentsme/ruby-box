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

    def folder(path)
      folder_from_split_path( split_path(path) )
    end

    def file(path)
      path = split_path(path)
      file_name = path.pop
      folder = folder_from_split_path( path )
      folder.files(file_name).first if folder
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
        folder = new_folder ? new_folder : folder.create_subfolder(folder_name)
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

    private

    def folder_from_split_path(path)
      folder = root_folder
      path.each do |folder_name|
        folder = folder.folders(folder_name).first
        return nil unless folder
      end
      folder
    end
    
  end
end