# frozen_string_literal: true

require 'json'
require 'sqlite3'
require './lib/utils'
require './lib/log'

class Cache
  def initialize(db_path)
    @db = SQLite3::Database.new(db_path)
    create_table
  end

  def read_with_cache(file_name, key, invalidate = false)
    raise 'Invalid key' unless key =~ /^[a-zA-Z0-9]+$/

    id_data = file_id(file_name, format: :json)
    cache_key = get_cache_key(id_data[:id], key)
    file_info = read_with_cache2(cache_key, invalidate)
    return file_info if file_info

    file_info = yield
    file_info.merge!(id_data)
    write_cache(file_name, key, file_info)

    # TODO: обратить внимание, почему проверка происходит здесь.
    LOG.error("Invalid phash for #{file_name}".red) unless file_info[:phash]

    file_info
  end

  def write_cache(file_name, key, data)
    raise 'Invalid key' unless key =~ /^[a-zA-Z0-9]+$/

    id_data = file_id(file_name, format: :json)
    cache_key = get_cache_key(id_data[:id], key)

    data_to_save = data.to_json
    @db.execute("INSERT OR REPLACE INTO cache (key, data) VALUES (?, ?)", [cache_key, data_to_save])
  end

  private

  def read_with_cache2(cache_key, invalidate)
    return nil if invalidate == :all

    result = @db.get_first_value("SELECT data FROM cache WHERE key = ?", cache_key)
    return nil unless result

    begin
      file_info = JSON.parse(result, symbolize_names: true)
    rescue JSON::ParserError
      LOG.error("Error parsing JSON: #{result}")
      return nil
    end

    if invalidate == :errors && file_info[:type] == 'error'
      LOG.debug("Trying to skip cache with error: #{cache_key}")
      return nil
    end

    LOG.debug("Read from cache: #{cache_key}")
    file_info
  end

  def get_cache_key(id, key)
    id_md5 = Digest::MD5.hexdigest(id)
    "#{key}:#{id_md5}"
  end

  def file_id(file_name, format: :plain)
    size = File.size(file_name)
    name = File.basename(file_name)
    mtime = File.mtime(file_name).to_i
    if format == :json
      {
        mtime:,
        size:,
        name:,
        id: "#{mtime} #{size} #{name}"
      }
    else
      "#{mtime} #{size} #{name}"
    end
  end

  def create_table
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS cache (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL
      );
    SQL
  end
end
