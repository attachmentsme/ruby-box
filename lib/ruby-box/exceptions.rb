module RubyBox 
  class ObjectNotFound < StandardError; end
  class AuthError < StandardError; end
  class RequestError < StandardError; end
  class ServerError < StandardError; end
  class ItemNameInUse < StandardError; end
end
