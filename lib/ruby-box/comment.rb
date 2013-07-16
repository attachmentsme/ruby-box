module RubyBox
  class Comment < Item
    
    private

    def resource_name
      'comments'
    end

    def has_mini_format?
      true
    end
  end
end