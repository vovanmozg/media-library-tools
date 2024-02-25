# frozen_string_literal: true

require 'spec_helper'
require './lib/cache'

describe Cache do
  it 'does not break if cache file exists but empty' do
    file_name = "#{@root}/new/1.jpg"
    FileUtils.cp('./spec/fixtures/media/1.jpg', file_name)

    cache_dir = "#{@root}/cache"
    cache_file_name = "#{cache_dir}/phash/81/8103342057741f7e567bf31345c16700.json"

    FileUtils.mkdir_p(File.dirname(cache_file_name))
    FileUtils.cp('./spec/fixtures/lib/cache/empty_json/phash/81/8103342057741f7e567bf31345c16700.json', cache_file_name)

    expected = {
      type: 'error',
      message: "Undefined type of #{file_name}"
    }

    data = described_class.new(cache_dir).read_with_cache(file_name, 'phash', false) do
      expected
    end

    expect(data).to eq(expected)
  end
end
