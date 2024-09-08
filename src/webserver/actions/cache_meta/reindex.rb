# frozen_string_literal: true

require './config/constants'
require './cache_meta_async'

class InvalidParamsError < StandardError; end

class CacheMetaAction
  class Reindex
    def initialize(media_dir:, db_file:)
      @media_dir = media_dir
      @db_file = db_file
    end

    def call
      CacheMetaAsync.new(@media_dir).call
    end
  end
end
