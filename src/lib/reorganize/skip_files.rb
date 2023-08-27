class SkipFiles
  def initialize(new_dir, dups_dir)
    @new_dir = new_dir
    @new_broken_dir = File.join(dups_dir, 'new_broken')

    raise 'Invalid dirs' if @new_dir.nil? || @new_dir.empty? || @new_broken_dir.nil? || @new_broken_dir.empty?
  end

  def call(data)
    bad = []
    actions = []
    # Исключить из обработки файлы, у которых длительность 0, размер файла 0,
    # ширина и высота не указаны

    data.each do |file_name, file_info|
      if !file_info[:width] || !file_info[:height]
        bad << file_name
        new_file_name = file_name.to_s.gsub(@new_dir, @new_broken_dir)

        actions << {
          type: :wrong_width_or_height,
          file_info: file_info,
          from: file_name,
          to: new_file_name
        }
        next
      end



      if file_info[:type] == 'video' && (file_info[:video_length] == 0 || file_info[:video_length].nil?)
        bad << file_name
        new_file_name = file_name.to_s.gsub(@new_dir, @new_broken_dir)

        actions << {
          type: :wrong_length,
          file_info: file_info,
          from: file_name,
          to: new_file_name
        }
        next
      end
    end

    [bad, { skipped: actions }]
  end
end
