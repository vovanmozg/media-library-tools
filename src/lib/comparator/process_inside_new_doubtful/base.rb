# frozen_string_literal: true

class ProcessInsideNewDoubtful
  class Base
    private

    def very_different?(distance)
      # Коэфициент похожести https://github.com/westonplatter/phashion
      unsimilar_threshold = 2
      distance > unsimilar_threshold
    end

    def length_equal?(file_info1, file_info2)
      file_info1[:video_length].to_i == file_info2[:video_length].to_i
    end

    def length_similar?(file_info1, file_info2)
      (file_info1[:video_length].to_f / file_info2[:video_length] - 1).abs <= 0.03
    end

    def ratio_equal?(file_info1, file_info2)
      Media.calculate_ratio(file_info1) == Media.calculate_ratio(file_info2)
    end

    def phash_almost_equal?(distance)
      similar_threshold = 0
      distance <= similar_threshold
    end
  end
end
