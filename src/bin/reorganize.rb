# frozen_string_literal: true

require './reorganize'

# dirs, use_cache = false, system = :linux

dirs = {
  existing_dir: '/vt/existing',
  new_dir: '/vt/new',
  dups_dir: '/vt/dups',
  data_dir: '/vt/data'
}

args = {
  system: :linux
}
ARGV.each do |arg|
  dirs[:real_new_dir] = arg.split('=')[1] if arg.start_with?('--real-new-dir')

  dirs[:real_existing_dir] = arg.split('=')[1] if arg.start_with?('--real-existing-dir')

  dirs[:real_dups_dir] = arg.split('=')[1] if arg.start_with?('--real-dups-dir')

  args[:system] = arg.split('=')[1].to_sym if arg.start_with?('--system')

  args[:use_cache] = arg.split('=')[1] == 'true' if arg.start_with?('--cache-meta')
end

Reorganizer.new(dirs, **args).call
