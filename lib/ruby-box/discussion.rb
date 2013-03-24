module RubyBox
  class Discussion < Item
    has_many :comments

    private

    def resource_name
      'discussions'
    end
  end
end