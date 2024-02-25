class Mover
  class ShortMeta

    # Формирует строку с метаинформацией о файле: длина, соотношение сторон, размеры
    def short_meta(file_info, file_info_to = nil)
      output = []

      output << "len: #{file_info[:video_length]}" if file_info[:video_length]
      output << "#{file_info[:width]}x#{file_info[:height]} (ratio #{file_info[:ratio]}), size: #{file_info[:size]}" if file_info[:ratio]
      output << "distance: #{file_info_to[:distance]}" if file_info_to
      output << "#{Time.at(file_info[:mtime]).strftime('%Y-%m-%d %H:%M:%S')}"
      return output.join(', ')
      #
      # return 'kuku short meta'
      # output = []
      #
      # len = file_info[:video_length]
      # output << "len: #{len}" if len
      #
      # w = file_info[:width]
      # h = file_info[:height]
      # size = file_info[:size]
      # if w && h
      #   ratio = xMedia.calculate_ratio(file_info)
      #   output << "#{w}x#{h} (ratio #{ratio}), size: #{size}"
      # else
      #   # @errors << "# No width/height for #{fn1}"
      # end
      #
      # if file_info_original
      #   distance = Phashion.hamming_distance(file_info[:phash], file_info_original[:phash])
      #   output << "distance: #{distance}"
      # end
      #
      # output << "#{Time.at(file_info[:mtime]).strftime('%Y-%m-%d %H:%M:%S')}"
      # output.join(', ')
    end
  end
end
