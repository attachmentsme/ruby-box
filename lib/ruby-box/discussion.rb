module RubyBox
  class Discussion < Item
    has_many :comments

    private

    def resource_name
      'discussions'
    end

    def has_mini_format?
      true
    end
  end
end