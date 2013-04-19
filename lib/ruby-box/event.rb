module RubyBox
  class Event < Item

    def source?
      !@raw_item['source'].nil?
    end

  end
end
