#encoding: UTF-8

require 'ruby-box'
require 'webmock/rspec'

describe RubyBox::EventResponse do
  before do
    @session = RubyBox::Session.new
    @client  = RubyBox::Client.new(@session)
    @events_json  = File.read 'spec/fixtures/events.json'
    @events = JSON.load @events_json
    stub_request(:get, /#{RubyBox::API_URL}\/events.*/).to_return(body: @events_json, :status => 200)
  end

  it 'returns an EventResponse with a chunk_size and next_stream_position' do
    eresp = @client.events
    eresp.instance_of?(RubyBox::EventResponse).should be_true
    eresp.events.instance_of?(Array).should be_true
    eresp.chunk_size.should eq(@events['chunk_size'])
    eresp.events.length.should eq(@events['chunk_size'])
    eresp.next_stream_position.should eq(@events['next_stream_position'])
  end

  describe '#events' do
    before do
      @response = @client.events
      @event = @response.events.first
    end

    it 'should return Event objects in the event response' do
      @event.instance_of?(RubyBox::Event).should be_true
    end

    it 'should return an #event_id' do
      @event.event_id.should eq(@events['entries'][0]['event_id'])
    end

    it 'should return a User for #created_by' do
      @event.created_by.instance_of?(RubyBox::User).should be_true
    end

    it 'should return an #event_type' do
      @event.event_type.should eq(@events['entries'][0]['event_type'])
    end

    it 'should return a #session_id' do
      @event.session_id.should eq(@events['entries'][0]['session_id'])
    end

    it 'should return an instantiated #source' do
      @event.source.instance_of?(RubyBox::Folder).should be_true
    end

  end

end

