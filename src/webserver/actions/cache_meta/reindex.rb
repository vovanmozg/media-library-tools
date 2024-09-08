# frozen_string_literal: true

require './config/constants'
require './cache_meta'

class InvalidParamsError < StandardError; end

class CacheMetaAction
  class Reindex
    def initialize(media_dir:, db_file:)
      @media_dir = media_dir
      @db_file = db_file
    end

    def call
      CacheMeta.new(@media_dir, @db_file).call(invalidate: :errors)
    end
  end
end
