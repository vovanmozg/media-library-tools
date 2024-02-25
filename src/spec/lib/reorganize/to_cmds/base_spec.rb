require './spec/spec_helper'
#require './lib/reorganize/to_cmds'

describe 'ToCmds::Base' do
  xit 'composes create directory commands' do
    real_dups_dir = 'C:\\dups'
    settings = { dups_dir: '/dups', real_dups_dir: real_dups_dir, system: :windows }
    converter = described_class.new(settings: settings)
    actual = converter.send(:mkdir_win_cmds, 'C:\\dups\\new_inside_full_dups\\x', real_dups_dir)
    expected_cmds = [
      'if not exist "C:\\dups\\new_inside_full_dups" mkdir "C:\\dups\\new_inside_full_dups"',
      'if not exist "C:\\dups\\new_inside_full_dups\\x" mkdir "C:\\dups\\new_inside_full_dups\\x"'
    ]
    expect(actual).to eq(expected_cmds)
  end
end
