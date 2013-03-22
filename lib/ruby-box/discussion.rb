module RubyBox
  class Discussion < Item

    def comments
      url = "#{RubyBox::API_URL}/#{resource_name}/#{id}/comments"
      resp = @session.get( url )
      resp['entries'].map {|i| Comment.new(@session, i)}
    end

    private

    def resource_name
      'discussions'
    end
  end
end