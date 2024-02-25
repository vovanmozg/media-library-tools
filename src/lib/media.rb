# frozen_string_literal: true

require './lib/cache'
require './lib/phash'
require './lib/invalidate_cache'

class Media
  # We don't want to process files with specific data
  SKIP_TYPES = ['JSON data'].freeze

  def initialize(cache_dir, log)
    @cache_dir = cache_dir
    @log = log
  end

  # Если в метод передан блок, то он будет вызван для каждого файла.
  # В блок будет передано событие, которое произошло при чтении файла.
  def read_file!(file_name, fm, invalidate_cache = false)
    type = get_type(file_name, fm)
    return if type.nil?

    info, is_cache_used = read_with_cache(file_name, invalidate_cache, type)

    if is_cache_used
      InvalidateCache.new.call(info, file_name, type, @cache_dir, @log)
      yield :files_from_cache if block_given?
    else
      @log.debug('Not in cache')
      yield :files_missing_in_cache if block_given?
    end

    info
  rescue FileReadingError => e
    yield :file_reading_errors if block_given?

    @log.error("Error reading file #{file_name}: #{e.message}".red)
    {
      type: 'error',
      message: "Error reading file #{file_name}: #{e.message}"
    }
  rescue FramesExtractionError => e
    yield :frames_extraction_errors if block_given?

    @log.error("Error extract frame from #{file_name}: #{e.message}".red)
    # rescue TypeError => e
    #   increase_counters(:type_errors)
    #     LOG.error("Error of type #{file_name}: #{e.messages}")
    {
      type: 'error',
      message: "Error extract frame from #{file_name}: #{e.message}"
    }
  rescue ImageReadingError => e
    yield :image_reading_error if block_given?

    message = "Error read Image props from #{file_name}: #{e.message}"
    @log.error(message.red)
    {
      type: 'error',
      message: message
    }
  rescue UnknownPhashError => e
    raise e unless e.message == 'Unknown pHash error'

    @log.error("#{e.message} for #{file_name}".red)
    {
      type: 'error',
      message: e.message
    }
  end

  private

  # TODO: move куда нибудь
  def calculate_partial_md5(filename)
    chunk = IO.read(filename, 16_384)
    raise FileReadingError if chunk.nil?

    Digest::MD5.hexdigest(chunk)
  end

  def read_with_cache(file_name, invalidate_cache, type)
    is_cache_used = 1
    info = Cache.new(@cache_dir).read_with_cache(file_name, 'phash', invalidate_cache) do
      is_cache_used = 0

      if type == 'error'
        {
          type: 'error',
          message: "Undefined type of #{file_name}"
        }
      else
        phash_calculator = Object.const_get("PHash#{type.capitalize}").new
        phash_calculator
          .get_file_info(file_name)
          .merge(partial_md5: calculate_partial_md5(file_name))
      end
    end

    [info, is_cache_used]
  end

  def image?(file_name, fm)
    type_string = fm.file(file_name)
    type_string.start_with?('GIF image data', 'JPEG image data', 'PNG image data', 'TIFF image data', 'PC bitmap')
  end

  def video?(file_name, fm)
    type_string = fm.file(file_name)
    type_string.start_with?('ISO Media', 'RIFF', 'MPEG sequence', 'Microsoft ASF')
  end

  # @return [String] type of file, or nil if file is not media.
  #  types: 'image', 'video', 'error'
  def get_type(file_name, fm)
    # TODO: extract type detection to separate method
    if image?(file_name, fm)
      type = 'image'
      @log.debug('Is picture')
      yield :image_files_count if block_given?
    elsif video?(file_name, fm)
      type = 'video'
      @log.debug('Is video')
      yield :video_files_count if block_given?
    else
      return if SKIP_TYPES.include?(file_type(file_name, fm))

      type = 'error'
      @log.debug('Is undefined type of file')
      yield :no_media_files_count if block_given?
    end

    type
  end

  def file_type(file_name, fm)
    fm.file(file_name)
  end

  # Отношение длины к ширине округленное до одного знака после запятой
  def self.calculate_ratio(file_info)
    ratio = (file_info[:width].to_f / file_info[:height].to_f)
    (ratio * 10).round / 10.0
  end
end
