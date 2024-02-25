require 'optparse'
require './lib/mover'


options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: move.rb [options]'

  opts.on('-m', '--operations_file=[OPERATIONS_FILE]', 'Path to operations file') do |v|
    options[:operations_file] = v
  end

  opts.on('-m', '--commands_file=[COMMANDS_FILE]', 'Path to resulting bash file') do |v|
    options[:commands_file] = v
  end
end
parser.parse!

Mover.new(settings: options).call
#      existing_dir: '/vt/existing', # source path (inside docker) to existing media files
#       new_dir: '/vt/new', # source path (inside docker) to new media files
#       dups_dir: '/vt/dups', # destination path (inside docker) for dups
#       data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
#       real_existing_dir: '/vt/existing',
#       real_new_dir: '/vt/new',
#       real_dups_dir: '/vt/dups',
