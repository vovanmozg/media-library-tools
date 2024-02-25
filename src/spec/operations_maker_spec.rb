# frozen_string_literal: true

require './spec/spec_helper'
require './operations_maker'

describe OperationsMaker do
  it 'creates bash file with full_dups move files commands' do
    data_dir = "#{@root}/data"
    FileUtils.mkdir_p(data_dir)
    FileUtils.cp('./spec/fixtures/operations_maker/full_dups-actions.json', "#{data_dir}/actions.json")

    described_class.new(settings: {
      data_dir: data_dir,
    }).call

    actual = jf('/data/operations.json', @root)
    # FileUtils.cp("#{data_dir}/operations.json", './spec/fixtures/operations_maker/operations.json')
    expected = jf('./spec/fixtures/operations_maker/full_dups-operations.json')
    expect(actual[:full_dups]).to match(expected[:full_dups])
    expect(actual).to match(expected)
  end

  it 'creates bash file with inside_new_full_dups move files commands' do
    data_dir = "#{@root}/data"
    FileUtils.mkdir_p(data_dir)
    FileUtils.cp('./spec/fixtures/operations_maker/inside_new_full_dups-actions.json', "#{data_dir}/actions.json")

    described_class.new(settings: {
      data_dir: data_dir,
      new_dir: '/mnt/media',
      real_new_dir: '/mnt/media/remove',
      real_dups_dir: '/mnt/media/dups',
    }).call

    actual = jf('/data/operations.json', @root)
    expected = jf('./spec/fixtures/operations_maker/inside_new_full_dups-operations.json')

    expect(actual[:inside_new_full_dups]).to match(expected[:inside_new_full_dups])
    expect(actual).to match(expected)
  end

  describe '#normalize' do
    it 'does not convert for linux end empty dirs' do
      converter = described_class.new(settings: { system: :linux })
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('/new/x/1.mp4')
    end

    it 'does not convert for windows end empty dirs' do
      converter = described_class.new(settings: { system: :windows })
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('/new/x/1.mp4')
    end

    it 'does not convert if wrong dirs' do
      settings = { new_dir: '/new', system: :windows }
      converter = described_class.new(settings: settings)
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('/new/x/1.mp4')
    end

    it 'converts path with file in new_dir for windows' do
      settings = { new_dir: '/new', real_new_dir: 'C:\\new', system: :windows }
      converter = described_class.new(settings: settings)
      actual = converter.send(:normalize, '/new')
      expect(actual).to eq('C:\\new')
    end

    it 'converts path with file in dups for windows' do
      settings = { dups_dir: '/dups', real_dups_dir: 'C:\\dups', system: :windows }
      converter = described_class.new(settings: settings)
      actual = converter.send(:normalize, '/dups')
      expect(actual).to eq('C:\\dups')
    end
  end
end
