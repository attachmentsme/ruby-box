module RubyBox
  class Item

    def initialize( session, raw_item )
      @session = session
      @raw_item = raw_item
    end

    def update
      @raw_item = reload_meta unless etag

      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      uri = URI.parse(url)

      request = Net::HTTP::Put.new(uri.path, {
        "if-match" => etag,
        "Content-Type" => 'application/json'
      })
      request.body = JSON.dump(serialize)

      @raw_item = @session.request(uri, request)
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
      key = method.to_s
      
      # update @raw_item hash if this appears to be a setter.
      setter = method.to_s.end_with?('=')
      key = key.slice(0...-1) if setter
      @raw_item[key] = args[0] if setter and update_fields.include?(key)
      
      return @raw_item[key]
    end

    private

    def serialize
      update_fields.inject({}) {|hash, field| hash[field] = @raw_item[field]; hash}
    end

  end
end