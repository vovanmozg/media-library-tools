class ProcessInsideNewDoubtful
  class Video < Base
    def find_dups(data)
      doubtful = Hash.new { |h, k| h[k] = [] }

      # iterate data to compare all elements each other. Skip comparison the same
      # element and skip comparison of elements that already have been compared
      data.select {|_,v| v[:type] == 'video' }.to_a.combination(2).each do |(file_name1, file_info1), (file_name2, file_info2)|
        # Дальше рассматриваем только более менее похожие файлы
        distance = Phashion.hamming_distance(file_info1[:phash], file_info2[:phash])
        next if very_different?(distance)

        # Если ratio отличается, значит видео разные
        next unless ratio_equal?(file_info1, file_info2)

        # Если длина видео отличается более чем на 5%, значит они разные
        next unless length_similar?(file_info1, file_info2)

        # Если хэши почти не отличаются, то значит видео одинаковые
        # или
        # Если длина у видео отличается, то либо разные файлы дали похожий
        # phash, либо это одинаковые файлы и отличаются по длине незначительно
        # например, обрезана одна секунда в начале или в конце.
        doubtful[file_name1] << file_name2
        doubtful[file_name2] << file_name1

        # Отмечу, что мы в хэше у нас есть попарные сравнения всех файлов
        # поэтому нет смысла обрабатывать сложные цепочки и сомнительной похожести
      end

      doubtful
    end
  end
end
