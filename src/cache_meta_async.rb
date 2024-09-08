# frozen_string_literal: true

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
require './webserver/workers/phash_worker'

class CacheMetaAsync
  def initialize(media_dir)
    raise if media_dir.nil? || media_dir.empty?

    @media_dir = media_dir
    @dir_reader = DirReader.new(log: LOG)
  end

  def call
    @dir_reader.scan_files(@media_dir) do |file_name|
      PhashWorker.perform_async(file_name)
    end
  end
end
