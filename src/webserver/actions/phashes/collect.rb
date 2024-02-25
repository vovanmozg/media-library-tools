# frozen_string_literal: true

require 'colored'
require './lib/read_phashes'

class Phashes; end

class Phashes
  class Collect
    def initialize(media_dirs, cache_dir, log)
      @media_dirs = media_dirs
      @cache_dir = cache_dir
      @log = log
      @phash_reader = ReadPhashes.new(cache_dir)
    end

    def from_filesystem
      # CollectPhashes.new('/vt/media', '/vt/cache', '/vt/media').call
      data = {}
      @media_dirs.each do |media_dir|
        result = @phash_reader.from_filesystem(media_dir, media_dir)
        data.merge!(result)
      end

      @phash_reader.save(data)
    end

    def from_cache
      ReadPhashes.new(@cache_dir)
    end
  end
end
