require 'find'
require 'filemagic'
require './lib/media'

class Sort; end
class Sort::Index
  FM = FileMagic.new

  def call(items_count = 50)
    @media = Media.new('/vt/new', LOG)

    infos = []

    scan_files('/vt/new', items_count, LOG) do |file_name|
      info = @media.read_file!(file_name, FM)
      info[:file_name] = file_name
      infos << info
    end

    infos
  end

  def scan_files(dir_name, count = 50, log)
    exts = %w(3gp 3gpp ai avi bmp bup cds dcm dng eps gif h264 jpeg jpg m4a m4v mov mp4 mpg mpo mts ogv png ptl scn svg tif vob webp wlmp wma wmf wmv)
    exts += exts.map(&:upcase)
    allow = exts.product([1]).to_h

    files = []
    Find.find(dir_name) do |path|
      if File.file?(path)
        ext = File.extname(path)[1..-1]
        files << path if allow[ext]
        break if files.size >= count # Ограничиваем количество файлов до 10
      end
    end

    files.each do |file_name|
      yield file_name
    end
  end
end
