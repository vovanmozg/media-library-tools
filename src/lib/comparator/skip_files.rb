class SkipFiles
  def initialize(new_dir, dups_dir)
    @new_dir = new_dir
    @dups_dir = dups_dir
    @new_broken_dir = File.join(dups_dir, 'new_broken')

    raise 'Invalid dirs' if @new_dir.nil? || @new_dir.empty? || @new_broken_dir.nil? || @new_broken_dir.empty?
  end

  def call(data)
    bad = []
    actions = []
    # Исключить из обработки файлы, у которых длительность 0, размер файла 0,
    # ширина и высота не указаны

    data.each do |relative_path, file_info|
      if !file_info[:width] || !file_info[:height]
        bad << relative_path

        actions << {
          type: :wrong_width_or_height,
          from: file_info.merge(relative_path: relative_path.to_s, root: @new_dir),
          to: { root: @dups_dir, relative_path: File.join('new_broken', relative_path.to_s) },
        }
        next
      end

      if file_info[:type] == 'video' && (file_info[:video_length] == 0 || file_info[:video_length].nil?)
        bad << relative_path

        actions << {
          type: :wrong_length,
          from: file_info.merge(relative_path: relative_path.to_s),
          to: { root: @new_broken_dir, relative_path: relative_path.to_s }
        }
        next
      end
    end

    [bad, { skipped: actions }]
  end
end
