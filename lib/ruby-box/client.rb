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

    def create_folder(path)
      folder = root_folder
      folder_names = split_path(path)
      folder_names.each do |folder_name|
        new_folder = folder.folders(folder_name).first
        folder = new_folder ? new_folder : folder.create_subfolder(folder_name)
      end
      folder
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