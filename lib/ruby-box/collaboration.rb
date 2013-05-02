module RubyBox
  class Collaboration < Item

    private

    def resource_name
      'collaborations'
    end

    def update_fields
      ['role', 'status']
    end

  end
end
