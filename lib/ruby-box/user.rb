module RubyBox
  class User < Item
    
    def company 
      @raw_item["enterprise"]
    end
    
    private

    def resource_name
      'users'
    end
    
  end
end