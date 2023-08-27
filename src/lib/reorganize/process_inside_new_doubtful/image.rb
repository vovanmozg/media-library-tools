class ProcessInsideNewDoubtful
  class Image < Base
    def find_dups(data)
      doubtful = Hash.new { |h, k| h[k] = [] }

      # iterate data to compare all elements each other. Skip comparison the same
      # element and skip comparison of elements that already have been compared
      data.select {|_,v| v[:type] == 'image' }.to_a.combination(2).each do |(file_name1, file_info1), (file_name2, file_info2)|
        # рассматриваем только более менее похожие файлы
        distance = Phashion.hamming_distance(file_info1[:phash], file_info2[:phash])
        next if very_different?(distance)

        # Если ratio отличается, значит видео разные
        next unless ratio_equal?(file_info1, file_info2)

        doubtful[file_name1] << file_name2
        doubtful[file_name2] << file_name1

        # Отмечу, что мы в хэше у нас есть попарные сравнения всех файлов
        # поэтому нет смысла обрабатывать сложные сомнительной похожести
      end

      doubtful
    end
  end
end
