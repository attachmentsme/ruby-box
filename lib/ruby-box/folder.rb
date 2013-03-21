module RubyBox
  class Folder < Item
    def items(item_limit=100, offset=0)
      Enumerator.new do |yielder|
        while true
          url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/items?limit=#{item_limit}&offset=#{offset}"
          resp = @session.get( url )
          resp['entries'].each do |entry|
            yielder.yield(RubyBox::Item.factory(@session, entry))
          end
          offset += resp['entries'].count
          break if resp['offset'].to_i + resp['limit'].to_i >= resp['total_count'].to_i
        end
      end
    end

    def files(name=nil, item_limit=100, offset=0)
      items(item_limit, offset).select do |item|
        item.kind_of? RubyBox::File and (name.nil? or item.name == name)
      end
    end

    def folders(name=nil, item_limit=100, offset=0)
      items(item_limit, offset).select do |item|
        item.kind_of? RubyBox::Folder and (name.nil? or item.name == name)
      end
    end

    def discussions
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/discussions"
      resp = @session.get( url )
      resp['entries'].map {|i| Discussion.new(@session, i)}
    end

    def upload_file(filename, data)
      file = RubyBox::File.new(@session, {
        'name' => filename,
        'parent' => {'id' => id}
      })

      begin
        resp = file.upload_content(data) #write a new file. If there is a conflict, update the conflicted file.
      rescue RubyBox::ItemNameInUse => e
        file = RubyBox::File.new(@session, {
          'id' => e['context_info']['conflicts'][0]['id']
        })
        data.rewind
        resp = file.update_content( data )
      end
    end

    def create_subfolder(name)
      url = "#{RubyBox::API_URL}/#{resource_name}"
      uri = URI.parse(url)
      request = Net::HTTP::Post.new( uri.request_uri )
      request.body = JSON.dump({ "name" => name, "parent" => {"id" => id} })
      resp = @session.request(uri, request)
      RubyBox::Folder.new(@session, resp)
    end

    private

    def resource_name
      'folders'
    end
  end
end