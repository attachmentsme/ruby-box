require 'time'

module RubyBox
  class Item

    @@has_many = []
    @@has_many_paginated = []

    def initialize( session, raw_item )
      @session = session
      @raw_item = raw_item
    end

    def self.has_many(*keys)
      keys.each {|key| @@has_many << key.to_s}
    end

    def self.has_many_paginated(*keys)
      keys.each {|key| @@has_many_paginated << key.to_s}
    end

    def update
      reload_meta unless etag

      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      uri = URI.parse(url)

      request = Net::HTTP::Put.new(uri.path, {
        "if-match" => etag,
        "Content-Type" => 'application/json'
      })
      request.body = JSON.dump(serialize)

      @raw_item = @session.request(uri, request)
      self
    end

    def delete
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      resp = @session.delete( url )
    end

    def reload_meta
      url = "#{RubyBox::API_URL}/#{resource_name}/#{@raw_item['id']}"
      @raw_item = @session.get( url )
      self
    end

    def method_missing(method, *args, &block)
      key = method.to_s

      # Support has many and paginated has many relationships.
      return many(key) if @@has_many.include?(key)
      return paginated(key, args[0] || 100, args[1] || 0) if @@has_many_paginated.include?(key)
      
      # update @raw_item hash if this appears to be a setter.
      setter = method.to_s.end_with?('=')
      key = key[0...-1] if setter
      @raw_item[key] = args[0] if setter and update_fields.include?(key)
      
      # we may have a mini version of the object loaded, fix this.
      reload_meta if @raw_item[key].nil? and has_mini_format?

      if @raw_item[key].kind_of?(Hash)
        return RubyBox::Item.factory(@session, @raw_item[key])
      elsif RubyBox::ISO_8601_TEST.match(@raw_item[key].to_s)
        return Time.parse(@raw_item[key])
      else
        return @raw_item[key]
      end
    end

    protected

    def self.factory(session, entry)
      type = entry['type'].capitalize.to_sym
      if RubyBox.constants.include? type
        RubyBox.const_get(type).new(session, entry)
      else
        entry
      end
    end

    def has_mini_format?
      true
    end

    private

    def many(key)
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/#{key}"
      resp = @session.get( url )
      resp['entries'].map {|i| RubyBox::Item.factory(@session, i)}
    end

    def paginated(key, item_limit=100, offset=0)
      Enumerator.new do |yielder|
        while true
          url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/#{key}?limit=#{item_limit}&offset=#{offset}"
          resp = @session.get( url )
          resp['entries'].each do |entry|
            yielder.yield(RubyBox::Item.factory(@session, entry))
          end
          offset += resp['entries'].count
          break if resp['offset'].to_i + resp['limit'].to_i >= resp['total_count'].to_i
        end
      end
    end

    def serialize
      update_fields.inject({}) {|hash, field| hash[field] = @raw_item[field]; hash}
    end

  end
end
