# frozen_string_literal: true

require 'spec_helper'
require './lib/cache'

describe Cache do
  it 'does not break if cache file exists but empty' do
    file_name = "#{@root}/new/1.jpg"
    FileUtils.cp('./spec/fixtures/media/1.jpg', file_name)
    FileUtils.touch(file_name, mtime: 1_600_000_000)

    cache_dir = "#{@root}/cache"
    FileUtils.mkdir_p(cache_dir)

    cache_db = File.join(cache_dir, 'cache.db')
    cache_key = '84c123ac6279034cb1131ef78bc37c59'
    db = SQLite3::Database.new(cache_db)
    db.execute 'CREATE TABLE IF NOT EXISTS cache (key TEXT PRIMARY KEY, data TEXT NOT NULL);'
    db.execute('INSERT OR REPLACE INTO cache (key, data) VALUES (?, ?)', [cache_key, ''])

    expected = {
      type: 'error',
      message: "Undefined type of #{file_name}"
    }

    data = described_class.new.read(file_name, 'phash', false) do
      expected
    end

    expect(data).to eq(expected)
  end
end
