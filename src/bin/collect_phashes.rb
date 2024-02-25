# frozen_string_literal: true

require './collect_phashes'

real_media_dir = nil
ARGV.each do |arg|
  real_media_dir = arg.split('=')[1] if arg.start_with?('--real-media-dir')
end

CollectPhashes.new('/vt/media', '/vt/cache', real_media_dir).call
