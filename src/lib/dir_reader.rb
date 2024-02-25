# frozen_string_literal: true

require 'find'
require './lib/media'
require './lib/utils'

# Пример использования
# @dir_reader = DirReader.new(log: LOG)
# @dir_reader.scan_files(@media_dir) { |file_name| ... }
class DirReader
  def initialize(log:)
    @log = log
  end

  # @return [Hash] key - full path to file, value - hash with file info
  # @param [String] dir - path to directory with media files
  # @param [Symbol] meta_path - path to file to save meta info
  # @param [String] data_dir - path to directory with application data and cache files
  # @param [Boolean] cache - read cached data or not
  # @param [Boolean] invalidate_cache - write cache files or not
  #
  def parse_files(dir:, data_dir:, meta_path:, cache: true, invalidate_cache: false)
    raise 'data_dir is undefined' if data_dir.nil?

    cache_file = cache_file_name(data_dir, meta_path)

    if cache && File.exist?(cache_file)
      data = read_cache(cache_file)
      counters.increase(:from_cache)
    else
      data = parse_files_without_cache(dir: dir, data_dir: data_dir, validate: true)
    end

    write_cache(cache_file, data) if data && invalidate_cache

    data.tap { |data| validate_values!(data) }
  end

  def parse_files_without_cache(dir:, data_dir:, validate: true)
    raise 'data_dir is undefined' if data_dir.nil?

    media = Media.new(data_dir, @log)
    fm = FileMagic.new

    data = {}
    scan_files(dir) do |full_path, root_path, relative_path|
      # TODO: progress bar
      print '.' if @log.level == Logger::INFO

      file_info = media.read_file!(full_path, fm)
      if file_info
        data[relative_path] = file_info
        data[relative_path][:root] = root_path
      end
    end

    data.tap { |data| validate_values!(data) if validate }
  end

  def scan_files(dir_name)
    exts = %w(3gp 3gpp ai avi bmp bup cds dcm dng eps gif h264 jpeg jpg m4a m4v mov mp4 mpg mpo mts ogv png ptl scn svg tif vob webp wlmp wma wmf wmv)
    exts += exts.map(&:upcase)
    allow = exts.product([1]).to_h

    @log.info("Start search files #{dir_name}")

    files = []
    Find.find(dir_name) do |path|
      next unless File.file?(path)

      ext = File.extname(path)[1..]
      files << path if allow[ext]
    end

    @log.info("Found #{files.size} files in #{dir_name}")

    files.each do |full_path|
      @log.debug("Processing #{full_path}")
      relative_path = full_path[dir_name.size + 1..]
      yield full_path, dir_name, relative_path
    end
  end

  # @return [Hash] key - full path to file, value - hash with file info
  #
  #   Example of return Hash with one key
  #   {
  #   "/app/video_existing/2019-wa/20181201-WA0007.mp4": {
  #     "video_length": 180.86,
  #     "phash": 15591569520836312423,
  #     "width": 400,
  #     "height": 400,
  #     "partial_md5": "100eaca7339bfbabbf3b9e4b1e51542a",
  #     "size": 7406817,
  #     "name": "20181201-WA0007.mp4",
  #     "id": "100eaca7339bfbabbf3b9e4b1e51542a 7406817 20181201-WA0007.mp4"
  #   },
  # Если в папке произошли изменения, то нужно руками удалить файл existing_files.json
  # Дело в том, что после того, как скрипт прочитает все файлы, он запишет
  # результирующий объект в этот файл. И при следующем запуске, скрипт не будет
  # снова читать файлы, а просто возьмет закешированные данные. Поэтому если,
  # например, какой-то файл будет удален, то скрипт не узнает об этом и будет
  # думать, что этот файл есть. Этот файл будет участововать при поиске дублей
  # $current_type = :existing
  # def parse_files(dir:, type:, cache: false, data_dir:)
  #   @data_dir = data_dir
  #   @media = Media.new(data_dir, @log)
  #
  #   raise 'data_dir is undefined' if @data_dir.nil?
  #
  #   fm = FileMagic.new
  #   data = nil
  #   counters = Counters.new(type, @data_dir)
  #
  #   cache_file = cache_file_name(type, @data_dir)
  #   if cache && File.exist?(cache_file)
  #     data = read_hash(cache_file)
  #     counters.increase(:from_cache)
  #   end
  #
  #   unless data
  #     data = {}
  #     scan_files(dir) do |file_name|
  #       if @log.level == Logger::INFO
  #         print '.'
  #       end
  #       file_info = @media.read_file!(file_name, fm)
  #       data[file_name] = file_info if file_info
  #     end
  #
  #     IO.write(cache_file, JSON.pretty_generate(data)) if cache
  #   end
  #
  #   data.tap { |data| validate_values!(data) }
  # end

  def read_cache(cache_file)
    read_hash(cache_file)
  end

  def write_cache(cache_file, data)
    IO.write(cache_file, JSON.pretty_generate(data))
  end

  private

  def cache_file_name(data_dir, meta_path)
    File.join(data_dir, meta_path)
  end

  def validate_values!(data)
    data.each_value do |file_info|
      missing = InvalidateCache.new.find_missing_attributes(file_info, file_info[:type])
      raise "Missing attributes #{missing}" unless missing.empty?
    end
  end
end
