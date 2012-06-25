require 'uri'
require 'net/https'
require 'json'
require 'net/http/post/multipart'
require 'exceptions'

class RubyBox
  
  def initialize(api_key, auth_token)
    @api_key = api_key
    @auth_token = auth_token
  end
  
  def list(folder_id=0)
    url = "https://api.box.com/2.0/folders/#{folder_id}/items"
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri.request_uri)
    return do_http(uri, request)
  end
  
  def list_by_path(folder_path)
    folder_id = get_folder_id_for_path(folder_path)
    return list(folder_id)
  end
  
  def put_file(folder_id, file)
    url = "https://upload.box.com/api/2.0/files/data"
    uri = URI.parse(url)
    File.open(file) do |file_stream|
      request = Net::HTTP::Post::Multipart.new(uri.path, {
        "filename" => UploadIO.new(file_stream, "application/text", file),
        "folder_id" => folder_id
      })
      do_http(uri, request)
    end
  end
  
  def put_file_in_folder_path(folder_path, file)
    folder_id = get_folder_id_for_path(folder_path)
    put_file(folder_id, file)
  end 
  
  private
  
  def build_auth_header
    "BoxAuth api_key=#{@api_key}&auth_token=#{@auth_token}"
  end
  
  def get_folder_id_for_path(folder_path)
    current_folder_id = 0
    split_folders = folder_path.split('/')
    split_folders.each_with_index do |folder_name, index|
      next if index == split_folders.length
      list(current_folder_id)["entries"].each do |f|
        if (f["type"] == "folder" and f["name"] == folder_name)
          current_folder_id = f["id"]
          break
        end
      end
    end
    return current_folder_id
  end
  
  def do_http(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request.add_field('Authorization', build_auth_header)
    
    response = http.request(request)
    if response.is_a? Net::HTTPNotFound
      raise RBException::ObjectNotFound
    end
    return JSON.parse(response.body)
  end
end
