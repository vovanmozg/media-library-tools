require 'json'
require './lib/utils'
require './lib/log'

class Cache
  def initialize(cache_dir)
    @cache_dir = cache_dir
  end

  # Результат выполнения кэшируется в файлики в .mediacache
  # @param key - подпапка, в которую складывается кэш (нужна для визуального
  # разделения кэша по типам). Обычно равно phash
  # invalidate types
  # :all - invalidate all cache
  # :errors
  # false
  def read_with_cache(file_name, key, invalidate = false)
    raise 'Invalid key' unless key =~ /^[a-zA-Z0-9]+$/

    id_data = file_id(file_name, format: :json)
    cache_file_name = get_cache_file_name(id_data[:id], key)
    file_info = read_with_cache2(cache_file_name, invalidate)
    return file_info if file_info

    file_info = yield
    file_info.merge!(id_data)
    write_cache(file_name, key, file_info)

    # TODO: обратить внимание, почему проверка происходит здесь.
    unless file_info[:phash]
      LOG.error("Invalid phash for #{file_name}".red)
    end

    file_info
  end

  def write_cache(file_name, key, data)
    raise 'Invalid key' unless key =~ /^[a-zA-Z0-9]+$/

    id_data = file_id(file_name, format: :json)
    cache_file = get_cache_file_name(id_data[:id], key)

    data_to_save = data.to_json
    File.write(cache_file, data_to_save)
  end

  private

  def read_with_cache2(cache_file_name, invalidate)
    file_info = nil
    if invalidate == false
      if File.exist?(cache_file_name)
        LOG.debug("Read from cache file: #{cache_file_name}")
        file_info = read_hash(cache_file_name)
      end
    elsif invalidate == :errors
      if File.exist?(cache_file_name)
        LOG.debug("Read from cache file: #{cache_file_name}")
        file_info = read_hash(cache_file_name)
        if file_info && file_info[:type] == 'error'
          LOG.debug("Trying to skip cache with error: #{cache_file_name}")
          file_info = nil
        end
      end
    end
    file_info
  end

  def get_cache_file_name(id, key)
    id_md5 = Digest::MD5.hexdigest(id)
    cache_dir = cache_directory(id_md5, key)
    File.join(cache_dir, "#{id_md5}.json")
  end

  def cache_directory(md5, key)
    dir_splitter = md5[0..1]
    cache_dir = File.join(@cache_dir, key, dir_splitter)
    FileUtils.mkdir_p(cache_dir)
    cache_dir
  end

  def file_id(file_name, format: :plain)
    size = File.size(file_name)
    name = File.basename(file_name)
    mtime = File.mtime(file_name).to_i
    if format == :json
      {
        mtime: mtime,
        size: size,
        name: name,
        id: "#{mtime} #{size} #{name}"
      }
    else
      "#{mtime} #{size} #{name}"
    end
  end
end
