require 'phashion'

class Images; end
class Images::Dups

  # @param [Hash] image { filename: 'path', phash: 'phash' }
  def find(image, threshold = 15)
    @data = Phashes::Index.new(DATA_DIR).call

    similar_files = []
    @data.each do |file, file_phash|
      next if file == image[:file_name]

      distance = Phashion.hamming_distance(image[:phash].to_i, file_phash.to_i)
      if distance < threshold
        similar_files << { file: file, phash: file_phash, distance: distance }
      end
    end
    similar_files
  end
end
