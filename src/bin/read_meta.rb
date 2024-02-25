# frozen_string_literal: true

require 'optparse'
require './meta_reader'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: read_meta.rb [options]'

  opts.on('-m', '--media_meta_file=[MEDIA_META_FILE]', 'Path to media meta file') do |v|
    options[:media_meta_path] = v
  end

  opts.on('-m', '--media_dir=[MEDIA_DIR]', 'Path to directory with media files') do |v|
    options[:media_dir] = v
  end
end
parser.parse!

MetaReader.new(
  {
    media_dir: '/vt/media',
    data_dir: '/vt/data',
    media_meta_path: 'files_existing.json'
  }.merge(options)
).call
