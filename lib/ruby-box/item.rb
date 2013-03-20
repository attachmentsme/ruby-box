module RubyBox
  class Item

    def initialize( session, raw_item )
      @session = session
      @raw_item = raw_item
    end

    def delete
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      resp = @session.delete( url )
    end

    def reload_meta
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      @raw_item = @session.get( url )
    end

    def method_missing(method, *args, &block)
      return @raw_item[method.to_s]
    end

  end
end