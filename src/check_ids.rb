# frozen_string_literal: true

# Проверить насколько уникальным будет ID сформированный из
# - имени файла (без пути)
# - размера файла
# - даты изменения файла
#
# Замерить разницу в скорости вычисления id на основе 16 кб содержимого файла
# Вариант с чтением 16 кб из начала файла в 4-8 раз медленнее
# 50000 файлов обрабатываются за 1 секунду (запуск на локальном SSD)
#
# Пример запуска
# docker run --rm -it --name media_tools \
# 	-v /home/user/mediadata:/vt/media \
# 	-u=$UID:$UID \
# 	vovan/media_tools ruby ./check_ids.rb

require 'benchmark'
require 'digest'
require 'pry-byebug'
require './lib/utils'

def scan_files(dir_name, &block)
  pattern = File.join(dir_name, '**/**')
  files = Dir.glob(pattern).reject { |x| File.directory?(x) }

  files.each(&block)
end

class Fast
  def initialize(media_dir)
    raise if media_dir.nil? || media_dir.empty?

    @media_dir = media_dir
  end

  def call
    scan_files(@media_dir) do |file_name|
      name = File.basename(file_name)
      size = File.size(file_name).to_s
      mtime = File.mtime(file_name).to_s

      Digest::MD5.hexdigest("#{name} #{size} #{mtime}")
      # raise "#{name} #{size} #{mtime}" if dups[hash]
      #
      # dups[hash] = hash
    end
  end
end

class Md5
  def initialize(media_dir)
    raise if media_dir.nil? || media_dir.empty?

    @media_dir = media_dir
  end

  def call
    hash = {}
    scan_files(@media_dir) do |file_name|
      md5 = calculate_partial_md5(file_name)
      name = File.basename(file_name)
      size = File.size(file_name).to_s
      hash = Digest::MD5.hexdigest("#{md5} #{name} #{size}")
      # raise "#{md5} #{name} #{size}" if dups[hash]
      #
      # dups[hash] = hash
    end
  end

  def calculate_partial_md5(filename)
    chunk = IO.read(filename, 16_384)
    raise FileReadingError if chunk.nil?

    Digest::MD5.hexdigest(chunk)
  end
end

Benchmark.bm(3) do |x|
  x.report { Fast.new('/vt/media').call }
  x.report { Md5.new('/vt/media').call }
end
