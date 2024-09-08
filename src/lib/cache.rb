# frozen_string_literal: true

require 'sqlite3'
require './lib/utils'
require './lib/log'

class Cache
  def initialize(db_path)
    @db = SQLite3::Database.new(db_path)
    @db.results_as_hash = true
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

    LOG.error("Invalid phash for #{file_name}".red) unless file_info[:phash]

    file_info
  end

  def write_cache(file_name, key, data)
    raise 'Invalid key' unless key =~ /^[a-zA-Z0-9]+$/

    id_data = file_id(file_name, format: :json)
    cache_key = get_cache_key(id_data[:id], key)

    query = <<~SQL
      INSERT OR REPLACE INTO cache (
        key, mtime, size, name, phash, type, width, height, additional_data
      ) VALUES (
        :key, :mtime, :size, :name, :phash, :type, :width, :height, :additional_data
      )
    SQL
    @db.execute(query, {
                  key: cache_key,
                  mtime: data[:mtime],
                  size: data[:size],
                  name: data[:name],
                  phash: data[:phash].to_s,
                  type: data[:type],
                  width: data[:width],
                  height: data[:height],
                  additional_data: data.to_json
                })
  end

  private

  def read_with_cache2(cache_key, invalidate)
    return nil if invalidate == :all

    result = @db.get_first_row('SELECT * FROM cache WHERE key = ?', cache_key)
    return nil unless result

    file_info = {
      mtime: result['mtime'],
      size: result['size'],
      name: result['name'],
      phash: result['phash'],
      type: result['type'],
      width: result['width'],
      height: result['height']
    }

    begin
      additional_data = JSON.parse(result['additional_data'], symbolize_names: true)
      file_info.merge!(additional_data)
    rescue JSON::ParserError
      LOG.error("Error parsing JSON in additional_data: #{result['additional_data']}")
    end

    if invalidate == :errors && file_info[:type] == 'error'
      LOG.debug("Trying to skip cache with error: #{cache_key}")
      return nil
    end

    LOG.debug("Read from cache: #{cache_key}")
    file_info
  end

  def get_cache_key(id, _key)
    id_md5 = Digest::MD5.hexdigest(id)
    "#{id_md5}"
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
        mtime INTEGER,
        size INTEGER,
        name TEXT,
        phash TEXT,
        type TEXT,
        width INTEGER,
        height INTEGER,
        additional_data TEXT
      );
    SQL
  end
end
