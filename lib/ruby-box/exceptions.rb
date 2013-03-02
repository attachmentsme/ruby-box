module RubyBox 
  class Error < StandardError
    def initialize(error_json)
      @error_json = error_json
    end

    def [](key)
      @error_json[key]
    end
  end

  class ObjectNotFound < StandardError; end
  class AuthError < Error; end
  class RequestError < Error; end
  class ServerError < StandardError; end
  class ItemNameInUse < Error; end
end
