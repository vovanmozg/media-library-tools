# frozen_string_literal: true

require 'spec_helper'
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
        # existing_meta_file: '/vt/existing_files.json',
        # new_meta_file: '/vt/new_files.json',
        data_dir: "#{@root}/data",
        data_dir: "#{@root}/data",
      }
    ).call

    p result
  end

  it 'finds full dups in one directory' do
    data_dir = "#{@root}/data"
    media_dir = "#{@root}/new"
    FileUtils.mkdir_p([data_dir, media_dir])
    FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/1.jpg")
    FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/2.jpg")
    FileUtils.touch("#{@root}/new/1.jpg", mtime: 1_600_000_000)
    FileUtils.touch("#{@root}/new/2.jpg", mtime: 1_600_000_000)

    result = described_class.new(
      {
        # actions_path: '/vt/actions',
        actions: ['inside_new_full_dups'],
        # inside_new_similar: false,
        # inside_new_doubtful: false,
        # full_dups: false,
        # similar: false,
        # new_meta_file: '/vt/new_files.json',
        new_dir: "#{@root}/new",
        steps: ['read_meta', 'compare']
      }
    ).call

    p '------------------'

    p result

    p File.read(File.join(@root, result[:new_meta_file]))

  end
end
