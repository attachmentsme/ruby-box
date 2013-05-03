require 'ruby-box/client'
require 'ruby-box/session'

require 'ruby-box/item'
require 'ruby-box/file'
require 'ruby-box/folder'
require 'ruby-box/user'
require 'ruby-box/comment'
require 'ruby-box/collaboration'
require 'ruby-box/discussion'
require 'ruby-box/exceptions'
require 'ruby-box/event_response'
require 'ruby-box/event'
require 'ruby-box/web_link'

module RubyBox
  API_URL = 'https://api.box.com/2.0'
  UPLOAD_URL = 'https://upload.box.com/api/2.0'
  ISO_8601_TEST = Regexp.new(/^[0-9]{4}-[0-9]{2}-[0-9]{2}T/)
end
