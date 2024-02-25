class ProcessInsideNewSimilar
  def initialize(new_dir, dups_dir, log)
    @new_dir = new_dir
    @dups_dir = dups_dir
    @log = log
  end

  def call(data)
    processed_files, new_inside_full_dups, error_files = dups_groups(data)
    action_groups = generate_actions(new_inside_full_dups, data)

    [
      action_groups,
      processed_files,
      error_files,
    ]
  end

  private

  # В результате выполнения функции вернется new_inside_full_dups = {
  #  'file_name_1' => {
  #    'file_name_1' => file_info_1,
  #    'file_name_2' => file_info_2,
  #  }
  #  'file_name_3' => {
  #    'file_name_3' => file_info_3,
  #    'file_name_4' => file_info_4,
  #    'file_name_5' => file_info_5,
  # }
  #
  def dups_groups(data)
    by_md5 = data.group_by { |_, file_info| file_info[:phash] }
    error_files = []
    new_inside_full_dups = {}

    by_md5.each do |md5, files_infos|
      files = files_infos.to_h.keys
      next if files.count < 2


      # Определить элемент у которого самое большое разрешение
      max_resolution_item = max_dimensions_item(files, data)

      # Выбрать файлы с таким же разрешением
      max_resolution_items = same_dimensions_items(max_resolution_item, files, data)

      # Из файлов с максисмальным разрешением выбираем файл с минимальным
      # размером
      minimal_file = min_size_item(max_resolution_items, data)

      # Выбрать файлы с таким же размером
      minimal_files = same_size_items(minimal_file, max_resolution_items, data)

      #  Самый лучший файл - тот который самый старый
      groups_by_mtime = minimal_files.group_by { |file_name| data[file_name][:mtime] }
      oldest_mtime = groups_by_mtime.keys.min
      oldest_files = groups_by_mtime[oldest_mtime]

      # За оригинал примем файл с самым длинным имене файла. Это объясняется тем
      # что если имя файла длиннее, значит оно более информативное и лучше его
      # использовать как оригинал (хотя это не всегда так)
      best_match = oldest_files.max_by { |file_name| file_name.size }

      # Остальные нужно пометить как дубликаты
      files.each do |file_name|
        next if file_name == best_match

        new_inside_full_dups[file_name] = {
          original: best_match
        }
      end
    end

    processed_files = new_inside_full_dups.keys + error_files
    [
      # Уже обработанные файлы, их нужно исключить из обработки на последующих этапах
      processed_files,
      # Файлы, для которых нужно сформировать команды перемещения
      new_inside_full_dups,
      # Файлы, которые не удалось обработать
      error_files,
    ]
  end

  def generate_actions(new_inside_full_dups, data)
    actions = []

    new_inside_full_dups.each do |relative_path, groups|
      actions << {
        type: 'move',
        from: data[relative_path].merge(
          relative_path: relative_path
        ),
        to: {
          root: @dups_dir,
          relative_path: File.join('new_inside_similar', relative_path.to_s)
        },
        original: data[groups[:original]].merge(
          relative_path: groups[:original].to_s
        ),
      }
    end

    { inside_new_similar: actions }
  end

  def max_dimensions_item(files, data)
    files.max do |file_name1, file_name2|
      file_info1 = data[file_name1]
      file_info2 = data[file_name2]
      file_info1[:width].to_i * file_info1[:height].to_i <=>
        file_info2[:width].to_i * file_info2[:height].to_i
    end
  end

  def same_dimensions_items(max_resolution_item, cluster, data)
    cluster.select do |file_name|
      file_info = data[file_name]
      file_info[:width] == data[max_resolution_item][:width] && file_info[:height] == data[max_resolution_item][:height]
    end
  end

  def min_size_item(max_resolution_items, data)
    max_resolution_items.min do |file_name1, file_name2|
      file_info1 = data[file_name1]
      file_info2 = data[file_name2]
      file_info1[:size].to_i <=> file_info2[:size].to_i
    end
  end

  def same_size_items(minimal_file, max_resolution_items, data)
    max_resolution_items.select do |file_name|
      data[file_name][:size] == data[minimal_file][:size]
    end
  end
end
