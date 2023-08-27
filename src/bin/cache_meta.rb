require './cache_meta'

CacheMeta.new('/vt/media', '/vt/cache').call(invalidate: :errors)
