require './spec/spec_helper'
require './meta_reader.rb'

describe MetaReader do
  it 'creates one cache file with all files metas' do
    cache_dir = "#{@root}/data"
    media_dir = "#{@root}/media"
    FileUtils.mkdir_p([cache_dir, media_dir])
    FileUtils.cp('./spec/fixtures/media/1.mp4', "#{@root}/media/1.mp4")
    FileUtils.touch("#{@root}/media/1.mp4", mtime: 1_600_000_000)
    FileUtils.cp('./spec/fixtures/media/3 broken.mp4', "#{@root}/media/3 broken.mp4")
    FileUtils.touch("#{@root}/media/3 broken.mp4", mtime: 1_600_000_000)
    FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/media/1.jpg")
    FileUtils.touch("#{@root}/media/1.jpg", mtime: 1_600_000_000)

    described_class.new(
      media_dir: media_dir,
      data_dir: "#{@root}/data",
      media_meta_path: 'files.json'
    ).call

    expected = jf('./spec/fixtures/meta_reader/files.json')
    actual = jf("/data/files.json", @root)
    expect(actual).to eq(expected)
  end
end
