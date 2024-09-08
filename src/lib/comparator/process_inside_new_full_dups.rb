# frozen_string_literal: true

class ProcessInsideNewFullDups
  # DUPS_DIR = 'define_your_dir_here'
  # NEW_FILES_DIR = 'define_your_dir_here'

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
      error_files
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
    by_md5 = data.group_by { |_, file_info| file_info[:md5] }
    error_files = []
    new_inside_full_dups = {}

    by_md5.each do |md5, files_infos|
      files = files_infos.to_h.keys
      next if files.count < 2

      # Если первые килобайты файла одинаковые, а phash разные, то, все таки
      # считаем файлы разными. Пропускаем: пусть обрабатывается на последующих
      # этапах
      if have_different_phash?(files, data)
        @log.warn("Different phash for files with same md5: #{md5} #{files}")
        error_files += files
        next
      end

      # TODO: Добавить дополнительный выбор лучшего файла на основе даты.
      #  Самый лучший файл - тот который самый старый
      groups_by_mtime = files.group_by { |file_name| data[file_name][:mtime] }
      oldest_mtime = groups_by_mtime.keys.min
      oldest_files = groups_by_mtime[oldest_mtime]

      # За оригинал примем файл с самым длинным имене файла. Это объясняется тем
      # что если имя файла длиннее, значит оно более информативное и лучше его
      # использовать как оригинал (хотя это не всегда так)
      best_match = oldest_files.max_by(&:size)

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
      error_files
    ]
  end

  def have_different_phash?(files, data)
    phashes = files.map { |file_name| data[file_name][:phash] }.uniq
    phashes.count > 1
  end

  def generate_actions(new_inside_full_dups, data)
    actions = []

    new_inside_full_dups.each do |relative_path, groups|
      root_dups_dir = File.join(@dups_dir, 'new_inside_full_dups')
      relative_path.to_s.gsub(@new_dir, root_dups_dir)
      actions << {
        type: 'move',
        from: data[relative_path].merge(
          relative_path:
        ),
        to: {
          root: @dups_dir,
          relative_path: File.join('new_inside_full_dups', relative_path.to_s)
        },
        original: data[groups[:original]].merge(
          relative_path: groups[:original].to_s
        )
      }
    end

    {inside_new_full_dups: actions}
  end
end
