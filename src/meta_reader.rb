# frozen_string_literal: true

require 'pry-byebug'
require 'filemagic'
require './lib/utils'
require './lib/phash'
require './lib/scan_files'
require './lib/log'
require './lib/media'
require './lib/dir_reader'

class MetaReader
  def initialize(settings)
    @settings = {
      media_dir: '/vt/media', # source path (inside docker) to existing media files
      data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
      media_meta_path: 'files.json'
    }.merge(settings)

    @media_dir = @settings[:media_dir]
    @data_dir = @settings[:data_dir]
    @meta_path = @settings[:media_meta_path]

    raise if @media_dir.nil? || @media_dir.empty? || @data_dir.nil? || @data_dir.empty?

    @media = Media.new(@data_dir, LOG)
    @dir_reader = DirReader.new(log: LOG)
  end

  def call
    @dir_reader.parse_files(dir: @media_dir, meta_path: @meta_path, data_dir: @data_dir, cache: false,
                            invalidate_cache: true)
  end
end
