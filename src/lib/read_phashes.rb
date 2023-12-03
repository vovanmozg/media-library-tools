# Читает все файлы и сохраняет hpash и имя файла в файл phashes.txt

require 'json'
require 'filemagic'
require './lib/scan_files'
require './lib/log'
require './lib/media'
require './lib/simple_cache'

class ReadPhashes
  def initialize(cache_dir)
    raise if cache_dir.nil? || cache_dir.empty?

    @cache_dir = cache_dir
    @media = Media.new(cache_dir, LOG)
  end

  def from_filesystem(media_dir, real_media_dir)
    raise if media_dir.nil? || media_dir.empty? || real_media_dir.nil? || real_media_dir.empty?

    @media_dir = media_dir
    @real_media_dir = real_media_dir

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

    data
  end

  def from_cache
    data = SimpleCache.instance.read('phashes')
    return data if data

    file_name = "#{@cache_dir}/phashes.json"
    return {} unless File.exist?(file_name)

    data = JSON.parse(File.read(file_name))
    SimpleCache.instance.write('phashes', data)

    data
  end

  def save(data)
    # write to file in following format
    # phash1  file_name
    # phash2  file_name
    File.write("#{@cache_dir}/phashes.json", data.to_json)
    File.open("#{@cache_dir}/phashes.txt", 'w') do |f|
      data.each do |file_name, phash|
        # f.puts "#{phash} #{file_name.gsub(replace_from, replace_to)}" if phash
        f.puts "#{phash} #{file_name}" if phash
      end
    end
  end
end
