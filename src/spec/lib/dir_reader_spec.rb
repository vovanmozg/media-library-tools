# frozen_string_literal: true

require './spec/spec_helper'
require './lib/dir_reader'
require './lib/log'

describe DirReader do
  let(:cache_dir) { "#{@root}/cache" }

  it 'reads all files' do
    dir_reader = described_class.new(log: LOG)
    files = JSON.parse(
      dir_reader.parse_files(
        dir: './spec/fixtures/media',
        data_dir: cache_dir,
        meta_path: 'new_files.json'
      ).to_json,
      symbolize_names: true
    )
    expected = jf('./spec/fixtures/dir_reader/files.json')
    expect(files).to eq(expected)
  end
end
