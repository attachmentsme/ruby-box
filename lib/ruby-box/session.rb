require 'oauth2'

module RubyBox  
  class Session

    OAUTH2_URLS = {
      :site => 'https://www.box.com',
      :authorize_url => "/api/oauth2/authorize",
      :token_url => "/api/oauth2/token"
    }
    
    def initialize(opts={})
      if opts[:client_id]
        @oauth2_client = OAuth2::Client.new(opts[:client_id], opts[:client_secret], OAUTH2_URLS.dup)
        @access_token = OAuth2::AccessToken.new(@oauth2_client, opts[:access_token]) if opts[:access_token]
      else # Support legacy API for historical reasons.
        @api_key = opts[:api_key]
        @auth_token = opts[:auth_token]
      end
    end

    def authorize_url(redirect_uri)
      @redirect_uri = redirect_uri
      @oauth2_client.auth_code.authorize_url(:redirect_uri => redirect_uri)
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
    
    def request(uri, request, raw=false)      

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.ssl_version = :SSLv3
      
      if @access_token
        request.add_field('Authorization', "Bearer #{@access_token.token}")
      else
        request.add_field('Authorization', build_auth_header)
      end

      response = http.request(request)

      if response.is_a? Net::HTTPNotFound
        raise RubyBox::ObjectNotFound
      end
      handle_errors( response.code.to_i, response.body, raw )
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

      open(url, params)
    end
    
    def handle_errors( status, body, raw )
      begin
        parsed_body = JSON.parse(body)
      rescue
        msg = body.nil? || body.empty? ? "no data returned" : body
        parsed_body = { "message" =>  msg }
      end
      case status / 100
      when 4
        raise(RubyBox::ItemNameInUse.new(parsed_body), parsed_body["message"]) if parsed_body["code"] == "item_name_in_use"
        raise(RubyBox::AuthError.new(parsed_body), parsed_body["message"]) if parsed_body["code"] == "unauthorized" || status == 401        
        raise(RubyBox::RequestError.new(parsed_body), parsed_body["message"])
      when 5
        raise RubyBox::ServerError, parsed_body["message"]
      end
      raw ? body : parsed_body
    end
  end
end
