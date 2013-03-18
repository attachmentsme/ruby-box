module RubyBox
  class Item

    def initialize( session, raw_item )
      @root_id = raw_item['root_id']
      @session = session
      @raw_item = raw_item
    end

    def method_missing(method, *args, &block)
      return @raw_item[method]
    end

  end
end