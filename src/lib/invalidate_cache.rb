# frozen_string_literal: true

class InvalidateCache
  ATTRIBUTES = {
    image: %i[id height mtime name md5 phash size type width],
    video: %i[height id mtime name md5 phash size type video_length width]
  }.freeze

  def call(info, file_name, type, cache = nil)
    @cache = cache || Cache.new

    missing_attributes = find_missing_attributes(info, type)

    update_file_info(missing_attributes, info, file_name, type) unless missing_attributes.empty?
  end

  def find_missing_attributes(info, type)
    return [] unless ATTRIBUTES.key?(type.to_sym)
    missing_keys = ATTRIBUTES[type.to_sym] - info.keys
    missing_keys.empty? ? [] : missing_keys
  end

  private

  def update_file_info(missing_attributes, info, file_name, type)
    return if type == 'error' || info[:type] == 'error'

    missing_attributes.each do |key|
      info[key] = resolve_missing_attribute(key, file_name, type)
      @cache.write_cache(file_name, 'phash', info)
      LOG.debug("Existing cache updated with missing attributes: #{missing_attributes}")
    end
  end

  # Если не хватает обязательных атрибутов, то попробовать их добавить. Если
  # не хватает обязательных атрибутов, котоыре нельзя восстановить, то ругнуться
  def resolve_missing_attribute(key, file_name, type)
    case key
    when :mtime then resolve_mtime(file_name)
    when :type then type
    when :video_length then resolve_video_length(file_name)
    else raise "Missing key #{key}"
    end
  end

  def resolve_mtime(file_name)
    File.mtime(file_name).to_i
  end

  # TODO: возможно операции получения информации о файлах стоит перенести
  #  в одно место (phash или media)
  def resolve_video_length(file_name)
    PHashVideo.new.extract_video_length(file_name)
  end
end
