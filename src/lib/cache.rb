# frozen_string_literal: true

# require 'sqlite3'
require './lib/utils'
require './lib/log'
require './lib/db'

class Cache
  # KEYS = %i[mtime size name phash type width height id md5].freeze
  KEYS = ModelCache.columns.map(&:to_sym).freeze

  def initialize
    # create_table
  end

  def read(file_name, cache_key, invalidate = false)
    raise 'Invalid key' unless cache_key =~ /^[a-zA-Z0-9]+$/

    id_data = file_id(file_name, format: :json)
    db_id = get_db_id(id_data[:id])
    file_info = read_db(db_id, invalidate)
    return file_info if file_info

    file_info = yield
    file_info.merge!(id_data)
    write_cache(file_name, cache_key, file_info)

    LOG.error("Invalid phash for #{file_name}".red) unless file_info[:phash]

    file_info
  end

  # cache_key should determine table name
  def write_cache(file_name, cache_key, data)
    raise 'Invalid key' unless cache_key =~ /^[a-zA-Z0-9]+$/

    db_id = get_db_id(file_id(file_name))

    # query = <<~SQL
    #   INSERT OR REPLACE INTO cache (
    #     key, mtime, size, name, phash, type, width, height, id, md5, additional_data
    #   ) VALUES (
    #     :key, :mtime, :size, :name, :phash, :type, :width, :height, :id, :md5, :additional_data
    #   )
    # SQL

    # query_data = data
    #                .slice(*KEYS)
    #                .merge(
    #                  phash: data[:phash].to_s,
    #                  key: db_id,
    #                  additional_data: data.except(*KEYS).to_json
    #                )

    # DB.execute(query, query_data)
    ModelCache.create(
      data
        .slice(*KEYS)
        .merge(
          key: db_id,
          phash: data[:phash].to_s,
          additional_data: data.except(*KEYS).to_json
        ))
  end

  private

  def symbolize_keys(hash)
    hash.transform_keys(&:to_sym)
  end

  def format_result(data)
    data.merge!(
      JSON.parse(data[:additional_data], symbolize_names: true)
    )
    data[:phash] = data[:phash].to_i
    data.delete(:additional_data)
    data.delete(:key)
    data
  end

  def read_db(cache_key, invalidate)
    return nil if invalidate == :all

    # record = DB.get_first_row('SELECT * FROM cache WHERE key = ?', cache_key)
    record = ModelCache.where(key: cache_key).first
    return nil unless record

    file_info = record.to_hash.slice(*KEYS)

    begin
      format_result(file_info)
    rescue JSON::ParserError
      LOG.error("Error parsing JSON in additional_data: #{file_info[:additional_data]}")
    end

    if invalidate == :errors && file_info[:type] == 'error'
      LOG.debug("Trying to skip cache with error: #{cache_key}")
      return nil
    end

    LOG.debug("Read from cache: #{cache_key}")
    file_info.transform_keys(&:to_sym)
  end

  def get_db_id(file_id)
    Digest::MD5.hexdigest(file_id)
  end

  # Generates id for file. ID almost unique and based on file name, size and modify time.
  # The most reliable way to get unique id for file is to calculate md5 additionally.
  # But it is expensive. So we take set of params, which can be get quick without
  # and give pretty reliable and uniq id.
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

  # def create_table
  #   DB.execute <<-SQL
  #     CREATE TABLE IF NOT EXISTS cache (
  #       key TEXT PRIMARY KEY,
  #       mtime INTEGER,
  #       size INTEGER,
  #       name TEXT,
  #       phash TEXT,
  #       type TEXT,
  #       width INTEGER,
  #       height INTEGER,
  #       id TEXT,
  #       md5 TEXT,
  #       additional_data TEXT
  #     );
  #   SQL
  # end
end
