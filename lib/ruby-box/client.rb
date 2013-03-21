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
    
  end
end