require 'yaml'

ACCOUNT = {}
begin
  ACCOUNT = YAML.load_file(File.dirname(__FILE__) + '/account.yml')
rescue
  p "create an account.yml file with your credentials to run integration tests."
end
