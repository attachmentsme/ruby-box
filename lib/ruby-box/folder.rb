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
=begin
    def create( folder_name )
      url = "https://api.box.com/2.0/folders"
      uri = URI.parse(url)
      request = Net::HTTP::Post.new( uri.request_uri )
      request.body = { "name" => folder_name, "parent" => {"id" => @root_id} }.to_json
      resp = @xport.do_http( uri, request )
      fid = resp["id"] if resp["name"] == folder_name
      FFolder.new( @xport, fid )
    end
=end
    end

    private

    def resource_name
      'folders'
    end
  end
end