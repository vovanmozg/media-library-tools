# frozen_string_literal: true

require './spec/spec_helper'
require './lib/log'
require './lib/media'

describe Media do
  let(:cache_dir) { File.join(@root, 'cache') }
  let(:media_dir) { File.join(@root, 'media') }
  let(:fixtures) { './spec/fixtures/media' }
  let(:expected_dir) { './spec/fixtures/lib/media' }
  let(:media_file) { File.join(media_dir, name) }
  let(:source_file) { File.join(fixtures, name) }
  let(:expected_file) { File.join(expected_dir, "#{name}.json") }

  before(:each) do
    FileUtils.mkdir_p([cache_dir, media_dir])
    FileUtils.cp(source_file, media_file)
  end

  subject do
    described_class.new(cache_dir, LOG)
  end

  context '1.mp4' do
    let(:name) { '1.mp4' }

    it 'read_file! returns video meta' do
      FileUtils.touch(media_file, mtime: 1_600_000_000)
      meta = subject.read_file!(media_file, FileMagic.new)
      expected = {
        type: 'video',
        video_length: 4.44,
        phash: 408_042_780_191_318_620,
        width: 240,
        height: 180,
        partial_md5: 'cfbce21cac56843b4ef5fe2bac5b15d8',
        size: 442_877,
        name: '1.mp4',
        id: '1600000000 442877 1.mp4',
        mtime: 1_600_000_000
      }

      expect(meta).to eq(expected)
    end

    it 'read_file! updates cache with missing attributes' do
      cache_dir = "#{@root}/cache"
      media_dir = "#{@root}/media"
      FileUtils.mkdir_p([cache_dir, media_dir])
      FileUtils.cp('./spec/fixtures/media/1.mp4', "#{@root}/media/1.mp4")
      FileUtils.touch("#{@root}/media/1.mp4", mtime: 1_600_000_000)
      cache_file = "#{@root}/cache/phash/fc/fc240acdbd27652f831fb3ce6bf00925.json"
      FileUtils.mkdir_p("#{@root}/cache/phash/fc")
      FileUtils.cp('./spec/fixtures/media/missing_attributes/phash/fc/fc240acdbd27652f831fb3ce6bf00925.json', cache_file)

      subject.read_file!(media_file, FileMagic.new)

      actual = JSON.parse(IO.read(cache_file), symbolize_names: true)
      expected = {
        type: 'video',
        video_length: 4.44,
        phash: 408_042_780_191_318_620,
        width: 240,
        height: 180,
        partial_md5: 'cfbce21cac56843b4ef5fe2bac5b15d8',
        size: 442_877,
        name: '1.mp4',
        id: '1600000000 442877 1.mp4',
        mtime: 1_600_000_000
      }

      expect(actual).to eq(expected)
    end
  end

  context '5 broken.mp4' do
    let(:name) { '5 broken.mp4' }

    it 'read_file! returns video meta' do
      FileUtils.touch(media_file, mtime: 1_600_000_000)
      meta = subject.read_file!(media_file, FileMagic.new)
      expected = {
        type: 'error',
        message: "Error extract frame from #{media_dir}/5 broken.mp4: FramesExtractionError"
      }

      expect(meta).to eq(expected)
    end
  end

  context '1.jpg' do
    let(:name) { '1.jpg' }
    let(:expected) do
      {
        type: 'image',
        phash: 10_787_907_979_500_066_548,
        width: 250,
        height: 250,
        partial_md5: '63f3c713a01010bbcafdfafa3d688566',
        size: 8359,
        name: '1.jpg',
        id: '1600000000 8359 1.jpg',
        mtime: 1_600_000_000
      }
    end

    it 'read_file! returns image meta' do
      FileUtils.touch(media_file, mtime: 1_600_000_000)
      meta = subject.read_file!(media_file, FileMagic.new)
      expect(meta).to eq(expected)
    end

    it 'second read_file! returns meta from cache' do
      FileUtils.touch(media_file, mtime: 1_600_000_000)
      subject.read_file!(media_file,  FileMagic.new)
      meta = subject.read_file!(media_file, FileMagic.new)
      expect(meta).to eq(expected)
    end
  end

  # Unknown pHash error fixed by conversion to jpg
  xcontext 'when phash error' do
    let(:name) { '8 broken phash.gif' }
    let(:expected) do
      {
        type: 'error',
        message: 'Unknown pHash error'
      }
    end

    it 'returns error if unknown phash error happened' do
      meta = subject.read_file!(media_file, FileMagic.new)
      expect(meta).to eq(expected)
    end
  end
end
