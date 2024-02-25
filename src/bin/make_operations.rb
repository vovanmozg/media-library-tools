require 'optparse'
require './operations_maker'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: make_operations.rb [options]'

  opts.on('-m', '--media_meta_file=[MEDIA_META_FILE]', 'Path to media meta file') do |v|
    options[:media_meta_path] = v
  end

  opts.on('-m', '--actions_file=[ACTIONS_FILE]', '') do |v|
    options[:actions_file] = v
  end

  opts.on('-m', '--operations_file=[OPERATIONS_FILE]', '') do |v|
    options[:operations_file] = v
  end

  opts.on('-m', '--real_existing_dir=[REAL_EXISTING_DIR]', '') do |v|
    options[:real_existing_dir] = v
  end

  opts.on('-m', '--real_new_dir=[REAL_NEW_DIR]', '') do |v|
    options[:real_new_dir] = v
  end

  opts.on('-m', '--real_dups_dir=[REAL_DUPS_DIR]', '') do |v|
    options[:real_dups_dir] = v
  end
end
parser.parse!

OperationsMaker.new(settings: options).call
#      existing_dir: '/vt/existing', # source path (inside docker) to existing media files
#       new_dir: '/vt/new', # source path (inside docker) to new media files
#       dups_dir: '/vt/dups', # destination path (inside docker) for dups
#       data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
#       real_existing_dir: '/vt/existing',
#       real_new_dir: '/vt/new',
#       real_dups_dir: '/vt/dups',
