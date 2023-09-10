require './collect_phashes'

real_media_dir = nil
ARGV.each do|arg|
  if arg.start_with?('--real-media-dir')
    real_media_dir = arg.split('=')[1]
  end
end

CollectPhashes.new('/vt/media', '/vt/cache', real_media_dir).call
