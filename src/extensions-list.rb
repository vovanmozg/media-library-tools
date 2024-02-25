# frozen_string_literal: true

# Show list of extensions of all files in directory with subdirectories
# Example:
# docker run --rm --name media_tools -v /home/mediafiles:/app/media -u=$UID:$UID vovan/media_tools ./extensions-list.sh
media_dir = '/app/media'

files = Dir.glob(File.join(media_dir, '**/**')).reject { |x| File.directory?(x) }
extensions = files.map { |file_name| File.extname(file_name) }.uniq
puts extensions.join(' ')
