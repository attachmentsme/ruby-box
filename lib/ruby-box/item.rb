require 'time'
require 'addressable/uri'

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

    def move_to( folder_id, name=nil )
      # Allow either a folder_id or a folder object
      # to be passed in.
      folder_id = folder_id.id if folder_id.instance_of?(RubyBox::Folder)

      self.name = name if name
      self.parent = {"id" => folder_id}

      update
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

    def create
      url = "#{RubyBox::API_URL}/#{resource_name}"
      uri = URI.parse(url)
      request = Net::HTTP::Post.new( uri.request_uri )
      request.body = JSON.dump(@raw_item)
      resp = @session.request(uri, request)
      @raw_item = resp
      self
    end

    def delete(opts={})
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      url = "#{url}#{Addressable::URI.new(:query_values => opts).to_s}" unless opts.keys.empty?
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
      return paginated(key, args[0] || 100, args[1] || 0, args[2]) if @@has_many_paginated.include?(key)
      
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

    # see http://developers.box.com/docs/#folders-create-a-shared-link-for-a-folder
    # for a list of valid options.
    def create_shared_link(opts={})
      raise UnshareableResource unless ['folder', 'file'].include?(type)

      opts = {
        access: 'open'
      }.merge(opts) if opts

      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}"
      uri = URI.parse(url)

      request = Net::HTTP::Put.new(uri.path, {
        "Content-Type" => 'application/json'
      })

      request.body = JSON.dump({
        shared_link: opts
      })

      @raw_item = @session.request(uri, request)
      self
    end

    def disable_shared_link(opts={})
      create_shared_link(nil)
    end

    def shared_link
      return nil unless @raw_item['shared_link']
      RubyBox::Item.factory(@session, @raw_item['shared_link'].merge('type' => 'shared_link'))
    end

    def as_json(opts={})
      @raw_item
    end

    protected

    def self.factory(session, entry)
      type = entry['type'] ? entry['type'].split('_').map(&:capitalize).join('').to_sym : nil
      if RubyBox.constants.include? type
        RubyBox.const_get(type).new(session, entry)
      else
        RubyBox::Item.new(session, entry)
      end
    end

    def has_mini_format?
      false
    end

    private

    def many(key)
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/#{key}"
      resp = @session.get( url )
      resp['entries'].map {|i| RubyBox::Item.factory(@session, i)}
    end

    def paginated(key, item_limit=100, offset=0, fields=nil)
      Enumerator.new do |yielder|
        while true
          url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/#{key}?limit=#{item_limit}&offset=#{offset}"
          url = "#{url}&fields=#{fields.map(&:to_s).join(',')}" if fields
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

    def update_fields
      ['name', 'description', 'parent']
    end


  end
end
