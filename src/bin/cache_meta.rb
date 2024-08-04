# frozen_string_literal: true

require './cache_meta'

CacheMeta.new('/vt/media', '/vt/cache/cache.db').call(invalidate: :errors)
