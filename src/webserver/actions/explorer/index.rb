# frozen_string_literal: true

require 'find'
require 'filemagic'
require './lib/media'

class Explorer; end
class Explorer::Index
  FM = FileMagic.new

  # @param pattern [String] regexp для выбора файлов по пути
  def call(per: 50, page: 1, pattern: nil, threshold: 12)
    searcher = Images::Dups.new
    @media = Media.new('/vt/data', LOG)
    @threshold = threshold
    infos = []

    scan_files('/vt/new', per, pattern, LOG) do |file_name|
      info = @media.read_file!(file_name, FM)
      info[:file_name] = file_name
      info[:duplicates] = searcher.find(info, threshold).map do |dup|
        dup[:file_name] = @media.read_file!(dup[:file], FM)
        dup
      end

      infos << info
    end

    infos
  end

  def scan_files(dir_name, count = 50, pattern, log)
    exts = %w(3gp 3gpp ai avi bmp bup cds dcm dng eps gif h264 jpeg jpg m4a m4v mov mp4 mpg mpo mts ogv png ptl scn svg tif vob webp wlmp wma wmf wmv)
    exts += exts.map(&:upcase)
    allow = exts.product([1]).to_h

    files = []
    Find.find(dir_name) do |path|
      next if !pattern.nil? && path !~ /#{pattern}/

      if File.file?(path)
        ext = File.extname(path)[1..-1]
        files << path if allow[ext]
        break if files.size >= count # Ограничиваем количество файлов
      end
    end

    files.each do |file_name|
      yield file_name
    end
  end
end

