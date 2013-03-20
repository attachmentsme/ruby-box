require 'ruby-box/client'
require 'ruby-box/session'

require 'ruby-box/item'
require 'ruby-box/file'
require 'ruby-box/folder'
require 'ruby-box/comment'
require 'ruby-box/exceptions'

module RubyBox
  API_URL = 'https://api.box.com/2.0'
  UPLOAD_URL = 'https://upload.box.com/api/2.0'
  LEGACY_DOWNLOAD_URL = 'https://www.box.com/api/1.0/download/'
end
