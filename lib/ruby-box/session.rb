module RubyBox  
  class Session
    attr_accessor :api_key, :auth_token
    
    def initialize(api_key, auth_token)
      @api_key = api_key
      @auth_token = auth_token
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
      
      request.add_field('Authorization', build_auth_header)
      response = http.request(request)
      if response.is_a? Net::HTTPNotFound
        raise RubyBox::ObjectNotFound
      end
      handle_errors( response.code.to_i, response.body, raw )
    end

    def do_stream(url, opts)
      open(url, {
        'Authorization' => build_auth_header,
        :content_length_proc => opts[:content_length_proc],
        :progress_proc => opts[:progress_proc]
      })
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
        raise(RubyBox::AuthError.new(parsed_body), parsed_body["message"]) if parsed_body["code"] == "unauthorized"
        raise(RubyBox::RequestError.new(parsed_body), parsed_body["message"])
      when 5
        raise RubyBox::ServerError, parsed_body["message"]
      end
      raw ? body : parsed_body
    end
  end
end