# Читает все файлы и сохраняет hpash и имя файла в файл phashes.txt

require 'json'
require 'filemagic'
require './lib/scan_files'
require './lib/log'
require './lib/media'

class CollectPhashes
  def initialize(media_dir, cache_dir, real_media_dir)
    @phash_reader = ReadPhashes.new(cache_dir)

    @media_dir = media_dir
    @real_media_dir = real_media_dir
    # @cache_dir = cache_dir
    # @media = Media.new(cache_dir, LOG)
  end

  def call(cache: false)
    data = cache ? @phash_reader.from_cache : @phash_reader.from_filesystem(@media_dir, @real_media_dir)
    @phash_reader.save(data, @media_dir, @real_media_dir)
  end
  #
  # def from_filesystem
  #   data = {}
  #   scan_files(@media_dir, LOG) do |file_name|
  #     file_info = @media.read_file!(file_name, FileMagic.new) do |event|
  #       if LOG.level == Logger::INFO
  #         # refactor above code with switch
  #         case event
  #         when :files_from_cache
  #           print '+'
  #         when :files_missing_in_cache
  #           print '-'
  #         when :file_reading_errors
  #           print '*'
  #         when :frames_extraction_errors
  #           print '!'
  #         when :image_reading_error
  #           print '?'
  #         else
  #           print '.'
  #         end
  #       end
  #     end
  #     data[file_name] = file_info[:phash]
  #   end
  #   puts ''
  #   puts "Total files: #{data.size}"
  #   save(data)
  # end
  #
  # def from_cache
  #   file_name = "#{@cache_dir}/phashes"
  #   retun {} unless File.exist?(file_name)
  #
  #   JSON.parse(File.read(file_name))
  # end
  #
  # def save(data)
  #   # write to file in following format
  #   # phash1  file_name
  #   # phash2  file_name
  #   File.write("#{@cache_dir}/phashes.json", data.to_json)
  #   File.open("#{@cache_dir}/phashes.txt", 'w') do |f|
  #     data.each do |file_name, phash|
  #       f.puts "#{phash} #{file_name.gsub(@media_dir, @real_media_dir)}" if phash
  #     end
  #   end
  # end
end
