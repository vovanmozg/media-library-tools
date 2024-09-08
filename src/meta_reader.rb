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
  # @param media_dir [String] путь к директории с медиафайлами
  # @param data_dir [String] путь к директории с данными
  # @param media_meta_path [String] путь к файлу, куда сохранить метаданные
  def initialize(settings)
    @settings = {
      media_dir: '/vt/media', # source path (inside docker) to existing media files
      data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
      media_meta_path: 'files.json'
    }.merge(settings)

    @media_dir = @settings[:media_dir]
    @data_dir = @settings[:data_dir]
    @meta_path = @settings[:media_meta_path]

    raise 'media_dir is invalid' if @media_dir.nil? || @media_dir.empty?
    raise 'data_dir is invalid' if @data_dir.nil? || @data_dir.empty?
    
    @media = Media.new
    @dir_reader = DirReader.new(log: LOG)
  end

  def call
    @dir_reader.parse_files(dir: @media_dir, meta_path: @meta_path, data_dir: @data_dir, cache: false,
                            invalidate_cache: true)
  end
end
