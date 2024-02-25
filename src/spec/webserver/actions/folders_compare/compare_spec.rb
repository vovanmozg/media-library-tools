# frozen_string_literal: true

require './webserver/actions/folder_compare/compare'

describe FolderCompare::Compare do
  it 'should compare folders' do
    result = described_class.new(
      {
        actions_path: '/vt/actions',
        inside_new_full_dups: true,
        inside_new_similar: true,
        inside_new_doubtful: true,
        full_dups: true,
        similar: true,
        existing_meta_file: '/vt/existing_files.json',
        new_meta_file: '/vt/new_files.json'
      }
    ).call

    p result
  end
end
