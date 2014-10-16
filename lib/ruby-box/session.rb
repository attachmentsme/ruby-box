require 'oauth2'

module RubyBox
  class Session

    OAUTH2_URLS = {
      :site => 'https://www.box.com',
      :authorize_url => "/api/oauth2/authorize",
      :token_url => "/api/oauth2/token"
    }

    def initialize(opts={}, backoff=0.1)

      @backoff = backoff # try not to excessively hammer API.

      if opts[:client_id]
        @oauth2_client = OAuth2::Client.new(opts[:client_id], opts[:client_secret], OAUTH2_URLS.dup)
        @access_token = OAuth2::AccessToken.new(@oauth2_client, opts[:access_token]) if opts[:access_token]
        @refresh_token = opts[:refresh_token]
        @as_user = opts[:as_user]
      else # Support legacy API for historical reasons.
        @api_key = opts[:api_key]
        @auth_token = opts[:auth_token]
      end
    end

    def authorize_url(redirect_uri, state=nil)
      opts = { :redirect_uri => redirect_uri }
      opts[:state] = state if state

      @oauth2_client.auth_code.authorize_url(opts)
    end

    def get_access_token(code)
      @access_token = @oauth2_client.auth_code.get_token(code)
    end

    def refresh_token(refresh_token)
      refresh_access_token_obj = OAuth2::AccessToken.new(@oauth2_client, @access_token.token, {'refresh_token' => refresh_token})
      @access_token = refresh_access_token_obj.refresh!
    end

    def build_auth_header
      "BoxAuth api_key=#{@api_key}&auth_token=#{@auth_token}"
    end

    def get(url, raw=false)
      uri = URI.parse(url)
      request = Net::HTTP::Get.new( uri.request_uri )
      resp = request( uri, request, raw )
    end

    def delete(url, raw=false)
      uri = URI.parse(url)
      request = Net::HTTP::Delete.new( uri.request_uri )
      resp = request( uri, request, raw )
    end

    def request(uri, request, raw=false, retries=0)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      #http.set_debug_output($stdout)

      if @access_token
        request.add_field('Authorization', "Bearer #{@access_token.token}")
      else
        request.add_field('Authorization', build_auth_header)
      end


      request.add_field('As-User', "#{@as_user}") if @as_user

      response = http.request(request)

      if response.is_a? Net::HTTPNotFound
        raise RubyBox::ObjectNotFound
      end

      # Got unauthorized (401) status, try to refresh the token
      if response.code.to_i == 401 and @refresh_token and retries == 0
        refresh_token(@refresh_token)
        return request(uri, request, raw, retries + 1)
      end

      sleep(@backoff) # try not to excessively hammer API.

      handle_errors( response, raw )
    end

    def do_stream(url, opts)
      params = {
        :content_length_proc => opts[:content_length_proc],
        :progress_proc => opts[:progress_proc]
      }

      if @access_token
        params['Authorization'] = "Bearer #{@access_token.token}"
      else
        params['Authorization'] = build_auth_header
      end

      params['As-User'] = @as_user if @as_user

      open(url, params)
    end

    def handle_errors( response, raw )
      status = response.code.to_i
      body = response.body
      begin
        parsed_body = JSON.parse(body)
      rescue
        msg = body.nil? || body.empty? ? "no data returned" : body
        parsed_body = { "message" =>  msg }
      end

      # status is used to determine whether
      # we need to refresh the access token.
      parsed_body["status"] = status

      case status / 100
      when 3
        # 302 Found. We should return the url
        parsed_body["location"] = response["Location"] if status == 302
      when 4
        raise(RubyBox::ItemNameInUse.new(parsed_body, status, body), parsed_body["message"]) if parsed_body["code"] == "item_name_in_use"
        raise(RubyBox::AuthError.new(parsed_body, status, body), parsed_body["message"]) if parsed_body["code"] == "unauthorized" || status == 401
        raise(RubyBox::RequestError.new(parsed_body, status, body), parsed_body["message"])
      when 5
        raise(RubyBox::ServerError.new(parsed_body, status, body), parsed_body["message"])
      end
      raw ? body : parsed_body
    end
  end
end
