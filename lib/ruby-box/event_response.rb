module RubyBox
  class EventResponse < Item

    def events
      @events ||= entries.collect {|ev|
        RubyBox::Event.new(@session, ev)
      }
    end

    private

    def resource_name
      'events'
    end

    def has_mini_format?
      false
    end

  end
end
