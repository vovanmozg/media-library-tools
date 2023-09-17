class Images; end
class Images::Show
  def call(full_path, is_large = false, cache_dir)
    return { type: :stream, data: full_path } if is_large && File.exist?(full_path)

    cached_dir = File.join(cache_dir, 'thumbs')
    FileUtils.mkdir_p(cached_dir) unless Dir.exist?(cached_dir)

    cached_file_path = File.join(cached_dir, "#{Digest::MD5.hexdigest(full_path)}.jpg")

    if File.exist?(cached_file_path) && File.exist?(full_path)
      return {
        type: :stream,
        data: cached_file_path
      }
    end

    if File.exist?(full_path)
      image = repeated_read(full_path)

      new_width = DEFAULT_THUMB_WIDTH
      new_height = (image.rows * (new_width.to_f / image.columns)).to_i

      resized_image = image.resize(new_width, new_height)

      # Save to cache
      resized_image.write(cached_file_path)
      {
        type: :content,
        content: resized_image.to_blob
      }
    else
      {
        type: :error,
        data: [404, 'Image not found']
      }
    end
  end

  private

  def repeated_read(path)
    Magick::Image.read(path).first
  rescue Magick::ImageMagickError
    Magick::Image.read(path).first
  end
end
