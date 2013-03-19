module RubyBox
  class Item

    def initialize( session, raw_item )
      @session = session
      @raw_item = raw_item
    end

    def method_missing(method, *args, &block)
      return @raw_item[method.to_s]
    end

  end
end