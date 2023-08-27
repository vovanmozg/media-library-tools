require './spec/spec_helper'
require './lib/reorganize/to_cmds'

describe ToCmds::Base do
  describe '#normalize' do
    it 'does not convert for linux end empty dirs' do
      converter = described_class.new(system: :linux, dirs: {})
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('/new/x/1.mp4')
    end

    it 'does not convert for windows end empty dirs' do
      converter = described_class.new(system: :windows, dirs: {})
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('/new/x/1.mp4')
    end

    it 'does not convert if wrong dirs' do
      dirs = { new_dir: '/new' }
      converter = described_class.new(system: :windows, dirs: dirs)
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('/new/x/1.mp4')
    end

    it 'converts path with file in new_dir for windows' do
      dirs = { new_dir: '/new', real_new_dir: 'C:\\new' }
      converter = described_class.new(system: :windows, dirs: dirs)
      actual = converter.send(:normalize, '/new/x/1.mp4')
      expect(actual).to eq('C:\\new\\x\\1.mp4')
    end

    it 'converts path with file in dups for windows' do
      dirs = { dups_dir: '/dups', real_dups_dir: 'C:\\dups' }
      converter = described_class.new(system: :windows, dirs: dirs)
      actual = converter.send(:normalize, '/dups/new_inside_similar_doubtful/x/1.mp4')
      expect(actual).to eq('C:\\dups\\new_inside_similar_doubtful\\x\\1.mp4')
    end

  end

  it 'composes create directory commands' do
    real_dups_dir = 'C:\\dups'
    dirs = { dups_dir: '/dups', real_dups_dir: real_dups_dir }
    converter = described_class.new(system: :windows, dirs: dirs)
    actual = converter.send(:mkdir_win_cmds, 'C:\\dups\\new_inside_full_dups\\x', real_dups_dir)
    expected_cmds = [
      'if not exist "C:\\dups\\new_inside_full_dups" mkdir "C:\\dups\\new_inside_full_dups"',
      'if not exist "C:\\dups\\new_inside_full_dups\\x" mkdir "C:\\dups\\new_inside_full_dups\\x"'
    ]
    expect(actual).to eq(expected_cmds)
  end
end
