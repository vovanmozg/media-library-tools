# frozen_string_literal: true

require 'fastimage'
require 'fileutils'
require 'chunky_png'
require 'phashion'
require 'colored'
require 'json'
require 'rmagick'

class FramesExtractionError < StandardError; end

class ImageReadingError < StandardError; end

class UnknownPhashError < StandardError; end

class PHashImage
  def get_file_info(file_path)
    width, height = read_dimensions(file_path)

    raise ImageReadingError, "Can't read image dimensions" unless width && height

    {
      type: 'image',
      phash: PHashImage.phash(file_path),
      width:,
      height:,
      mtime: File.mtime(file_path).to_i
    }
  end

  def self.suppress_phash_error
    original_stderr = $stderr.clone
    $stderr.reopen(File.new('/dev/null', 'w'))
    yield
  rescue RuntimeError => e
    raise UnknownPhashError, e
  ensure
    $stderr.reopen(original_stderr)
  end

  def self.phash(file_name)
    # if extension is gif then convert to png first, and get phash from png file
    if File.extname(file_name) == '.gif'
      img_file_name = '/tmp/temp.jpg'
      `convert "#{file_name}" "#{img_file_name}"`
      file_name = img_file_name
    end

    suppress_phash_error do
      Phashion::Image.new(file_name).fingerprint
    end
  end

  private

  def read_dimensions(file_name)
    width, height = read_with_imagemagic(file_name)
    return [width, height] if width && height

    read_with_fastimage(file_name)
  end

  def read_with_imagemagic(file_name)
    image = Magick::Image.read(file_name).first
    return nil if image.nil?

    [image.columns, image.rows]
  rescue Magick::ImageMagickError
    nil
  end

  def read_with_fastimage(file_name)
    FastImage.size(file_name)
  end
end

class PHashVideo
  def get_file_info(video_path)
    # Directory to store the frames.
    frames_dir = '/tmp/frames'

    # Create the frames directory if it doesn't exist.
    FileUtils.mkdir_p(frames_dir)

    # Calculate frames per second (fps) for extraction. This will be used by
    # ffmpeg to determine how many frames to extract per second of video.
    frames_for_extraction = 10
    video_length = extract_video_length(video_path)
    fps = "1/#{video_length / frames_for_extraction}"

    # puts "video_length: #{video_length}, fps: #{fps}".green

    # Use ffmpeg to extract frames from the video at a calculated frame rate,
    # and scale the output frames.
    # -i: input file
    # -vf: filtergraph - Allows you to edit the video. Here we set fps and scale
    # fps=#{1/x}: Sets the frame rate for extraction.
    # scale=800:-1: Scales the width of the output frames to 800 pixels.
    # The height (-1) is automatically calculated to maintain the aspect ratio.
    # "#{frames_dir}/frame%03d.png": The output format for the frames.
    # %03d will be replaced with the frame number, zero-padded to 3 digits.
    `ffmpeg -i "#{video_path}" -vf "fps=#{fps},scale=800:-1" -loglevel error "#{frames_dir}/frame%03d.png"`
    check_frames!(frames_dir)

    # Prepare command for imagemagick's convert to stitch images together horizontally
    # convert +append #{apostrofed_files_to_join.join(' ')} out/output.png
    # +append: This option will append all input images side by side from left to right.
    # frame001.png frame002.png ...: List of input files
    # out/output.png: Output file
    apostrofed_files_to_join = files_to_join(frames_dir).map { |f| "'#{f}'" }
    cmd = "convert +append #{apostrofed_files_to_join.join(' ')} /tmp/output.png"
    `#{cmd}`

    # TODO: remove artefacts saving
    # base_name = File.basename(video_path)
    # `cp --backup=numbered /tmp/output.png ./artefacts/#{base_name}.png`

    # remove from /tmp/frames
    Dir.glob("#{frames_dir}/*.png").each do |frame|
      FileUtils.rm(frame)
    end

    phash = PHashImage.phash('/tmp/output.png')

    # Extract additional video metadata with ffprobe
    # -v quiet: Sets the logging level to quiet to avoid unnecessary output.
    # -print_format json: The output format of the data. In this case, JSON.
    # -show_format -show_streams: What information to show - format shows overall
    #  information about the media file, and streams shows information about each
    #  stream (video, audio, etc.) in the file.
    ffprobe_video_info = JSON.parse(`ffprobe -v quiet -print_format json -show_format -show_streams "#{video_path}"`,
                                    symbolize_names: true)

    {
      type: 'video',
      video_length:,
      phash:,
      width: ffprobe_video_info[:streams][0][:width],
      height: ffprobe_video_info[:streams][0][:height],
      mtime: File.mtime(video_path).to_i
    }

    # puts ffprobe_video_info
    # puts video_info
    # puts "#{video_info[:phash]}|#{video_info[:video_length]}"
  end

  def files_to_join(frames_dir)
    (1..9).map(&:to_s).map { |x| "#{frames_dir}/frame#{x.to_s.rjust(3, '0')}.png" }
  end

  def check_frames!(frames_dir)
    frames_exist = files_to_join(frames_dir).all? { |f| File.exist?(f) }
    raise FramesExtractionError unless frames_exist
  end

  def extract_video_length(filename)
    # -v error: Sets the logging level to error. Only errors will be shown.
    # -show_entries format=duration: Specifies what information to show. Here
    #  we're only interested in the duration of the video.
    # -of default=noprint_wrappers=1:nokey=1: Output format options. Here we're
    #  setting it to print just the value of the duration, without any additional information.
    `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{filename}"`.to_f
    # `ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 #{filename}`.to_i
  end

  # def write_median(grayscale_values)
  #   # Image dimensions
  #   width = 80
  #   height = 80
  #
  #   # Create a new ChunkyPNG image with the specified dimensions
  #   image = ChunkyPNG::Image.new(width, height)
  #
  #   # Loop over each pixel in the image
  #   grayscale_values.each_with_index do |value, index|
  #     # Calculate the x and y coordinates of the pixel
  #     x = index % width
  #     y = index / width
  #
  #     # Set the pixel value in the image
  #     image[x, y] = ChunkyPNG::Color.grayscale(value)
  #   end
  #
  #   # Save the image to a file
  #   image.save('/tmp/output.png')
  # end
end
