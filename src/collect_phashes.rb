# Читает все файлы и сохраняет hpash и имя файла в файл phashes.txt

require 'json'
require 'filemagic'
require './lib/scan_files'
require './lib/log'
require './lib/media'

class CollectPhashes
  def initialize(media_dir, cache_dir, real_media_dir)
    raise if media_dir.nil? || media_dir.empty? || cache_dir.nil? || cache_dir.empty? || real_media_dir.nil? || real_media_dir.empty?

    @media_dir = media_dir
    @cache_dir = cache_dir
    @real_media_dir = real_media_dir
    @media = Media.new(cache_dir, LOG)
  end

  def call
    data = {}
    scan_files(@media_dir, LOG) do |file_name|
      file_info = @media.read_file!(file_name, FileMagic.new) do |event|
        if LOG.level == Logger::INFO
          # refactor above code with switch
          case event
          when :files_from_cache
            print '+'
          when :files_missing_in_cache
            print '-'
          when :file_reading_errors
            print '*'
          when :frames_extraction_errors
            print '!'
          when :image_reading_error
            print '?'
          else
            print '.'
          end
        end
      end
      data[file_name] = file_info[:phash]
    end
    puts ''
    puts "Total files: #{data.size}"
    save(data)
  end

  def save(data)
    # write to file in following format
    # phash1  file_name
    # phash2  file_name
    File.write("#{@cache_dir}/phashes.json", data.to_json)
    File.open("#{@cache_dir}/phashes.txt", 'w') do |f|
      data.each do |file_name, phash|
        f.puts "#{phash} #{file_name.gsub(@media_dir, @real_media_dir)}" if phash
      end
    end
  end
end
