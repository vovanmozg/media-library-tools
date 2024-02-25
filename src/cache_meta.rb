# Три нижние строки комментария сомнительны
# Проверяет, есть ли в новых файлах дубликаты, которые уже есть в старых файлах.
# Если есть, то перемещает их в директорию для дубликатов.
# ruby cache.rb -n "/home/new_files" -c "/home/.mediacache"

require 'pry-byebug'
require 'filemagic'
require './lib/utils'
require './lib/phash'
require './lib/scan_files'
require './lib/log'
require './lib/media'
require './lib/dir_reader'

class CacheMeta
  def initialize(media_dir, data_dir)
    raise if media_dir.nil? || media_dir.empty? || data_dir.nil? || data_dir.empty?

    @media_dir = media_dir
    @data_dir = data_dir
    @media = Media.new(data_dir, LOG)
    @dir_reader = DirReader.new(log: LOG)
  end

  def call(invalidate: false)
    @invalidate = invalidate
    counters = Counters.new(:all, @data_dir)
    @dir_reader.scan_files(@media_dir) do |file_name|
      if LOG.level == Logger::INFO
        print '.'
      end
      update_cache(file_name) do |event|
        counters.increase(event)
      end
    end
  end

  def update_cache(file_name)
    @media.read_file!(file_name, FileMagic.new, @invalidate) do |event|
      yield event
    end
  end
end

