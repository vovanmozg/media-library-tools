require 'digest'
require 'zlib'

class FileReadingError < StandardError; end

def read_hash(file_name)
  # JSON.parse(File.read(file_name)).transform_keys(&:to_sym)
  JSON.parse(File.read(file_name), symbolize_names: true)
rescue JSON::ParserError
  nil
end

def to_boolean(string)
  return true if string == true || string == 'true'
  return false if string == false || string == 'false'

  raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
end
