module RubyBox
  class User < Item
    
    def enterprise
      resp = @session.get( "#{RubyBox::API_URL}/users/#{id}?fields=enterprise" )
      resp["enterprise"]
    end
    
    private

    def resource_name
      'users'
    end
    
  end
end