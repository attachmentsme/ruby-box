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

    private

    def resource_name
      'folders'
    end
  end
end