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

class CacheMeta
  def initialize(media_dir, cache_dir)
    raise if media_dir.nil? || media_dir.empty? || cache_dir.nil? || cache_dir.empty?

    @media_dir = media_dir
    @cache_dir = cache_dir
    @media = Media.new(cache_dir, LOG)
  end

  def call(invalidate: false)
    @invalidate = invalidate
    counters = Counters.new(:all, @cache_dir)
    scan_files(@media_dir, LOG) do |file_name|
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

