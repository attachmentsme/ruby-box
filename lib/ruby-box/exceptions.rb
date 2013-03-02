module RubyBox 
  class RubyBoxError < StandardError
    def initialize(error_json)
      @error_json = error_json
    end

    def [](key)
      @error_json[key]
    end
  end

  class ObjectNotFound < StandardError; end
  class AuthError < RubyBoxError; end
  class RequestError < RubyBoxError; end
  class ServerError < StandardError; end
  class ItemNameInUse < RubyBoxError; end
end
