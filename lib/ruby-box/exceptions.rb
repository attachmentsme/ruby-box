module RubyBox 
  class RubyBoxError < StandardError
    attr_accessor :body, :status

    def initialize(error_json, status, body)
      @status = status
      @body = body
      @error_json = error_json
    end

    def [](key)
      @error_json[key]
    end
  end

  class ObjectNotFound < StandardError; end
  class AuthError < RubyBoxError; end
  class RequestError < RubyBoxError; end
  class ServerError < RubyBoxError; end
  class ItemNameInUse < RubyBoxError; end
  class UnshareableResource < StandardError; end
end
