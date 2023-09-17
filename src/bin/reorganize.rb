require './reorganize'

# dirs, use_cache = false, system = :linux

dirs = {
  existing_dir: "/vt/existing",
  new_dir: "/vt/new",
  dups_dir: "/vt/dups",
  data_dir: "/vt/data"
}

args = {
  system: :linux
}
ARGV.each do|arg|
  if arg.start_with?('--real-new-dir')
    dirs[:real_new_dir] = arg.split('=')[1]
  end

  if arg.start_with?('--real-existing-dir')
    dirs[:real_existing_dir] = arg.split('=')[1]
  end

  if arg.start_with?('--real-dups-dir')
    dirs[:real_dups_dir] = arg.split('=')[1]
  end

  if arg.start_with?('--system')
    args[:system] = arg.split('=')[1].to_sym
  end

  if arg.start_with?('--cache-meta')
    args[:use_cache] = arg.split('=')[1] == 'true'
  end
end

Reorganizer.new(dirs, **args).call
