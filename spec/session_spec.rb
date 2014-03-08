#encoding: UTF-8

require 'spec_helper'
require 'ruby-box'

describe RubyBox::Client do
  before do
    @auth_code = double("OAuth2::Strategy::AuthCode")

    @client = double("OAuth2::Client")
    @client.should_receive(:auth_code) { @auth_code }
    OAuth2::Client.should_receive(:new) { @client }

    @session = RubyBox::Session.new({
      client_id: "client id",
      client_secret: "client secret"
    })
  end

  let(:redirect_uri) { "redirect_uri" }

  describe '#authorize_url' do
    it "should accept redirect_uri" do
      @auth_code.should_receive(:authorize_url).with({ redirect_uri: redirect_uri})
      @session.authorize_url(redirect_uri)
    end
  end

  describe '#authorize_url_with_state' do
    let(:state) { "state" }

    it "should accept redirect_uri and state" do
      @auth_code.should_receive(:authorize_url).with({ redirect_uri: redirect_uri, state: state})
      @session.authorize_url(redirect_uri, state)
    end
  end
end
