module RubyBox
  class Folder < Item
    def items(item_limit=100, offset=0)
      Enumerator.new do |yielder|
        while true
          url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/items?limit=#{item_limit}&offset=#{offset}"
          resp = @session.get( url )
          resp['entries'].each do |entry|
            case entry['type']
            when 'folder'
              yielder.yield(RubyBox::Folder.new(@session, entry))
            when 'file'
              yielder.yield(RubyBox::File.new(@session, entry))
            end
          end
          offset += resp['entries'].count
          break if resp['offset'].to_i + resp['limit'].to_i >= resp['total_count'].to_i
        end
      end
    end

    def upload_file(filename, data)

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

    private

    def resource_name
      'folders'
    end
  end
end