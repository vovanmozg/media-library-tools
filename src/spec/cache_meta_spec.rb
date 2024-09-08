# frozen_string_literal: true

require './spec/spec_helper'
require './cache_meta'

describe CacheMeta do
  it 'creates cache files' do
    cache_dir = "#{@root}/cache"
    media_dir = "#{@root}/new"
    FileUtils.mkdir_p([cache_dir, media_dir])
    FileUtils.cp('./spec/fixtures/media/1.mp4', "#{@root}/new/1.mp4")
    FileUtils.touch("#{@root}/new/1.mp4", mtime: 1_600_000_000)
    FileUtils.cp('./spec/fixtures/media/3 broken.mp4', "#{@root}/new/3 broken.mp4")
    FileUtils.touch("#{@root}/new/3 broken.mp4", mtime: 1_600_000_000)
    FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/1.jpg")
    FileUtils.touch("#{@root}/new/1.jpg", mtime: 1_600_000_000)

    CacheMeta.new(media_dir, cache_dir).call

    cached_keys = ModelCache.all.map(&:key)
    expected = %w[84c123ac6279034cb1131ef78bc37c59 fc240acdbd27652f831fb3ce6bf00925 4fa07c3b7dd592da690622e66d782368]
    expect(cached_keys).to eq(expected)
  end
end
