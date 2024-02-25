require './lib/phash'
require './lib/group_fnames'
require './lib/media'
require './lib/comparator/process_inside_new_doubtful/base'
require './lib/comparator/process_inside_new_doubtful/image'
require './lib/comparator/process_inside_new_doubtful/video'

class ProcessInsideNewDoubtful
  def initialize(new_dir, dups_dir, errors)
    @new_dir = new_dir
    @dups_dir = dups_dir
    @errors = errors
  end

  def find_dups(data)
    doubtful = Hash.new { |h, k| h[k] = [] }

    doubtful.merge!(ProcessInsideNewDoubtful::Image.new.find_dups(data))
    doubtful.merge!(ProcessInsideNewDoubtful::Video.new.find_dups(data))

    # Отмечу, что в хэше у нас есть попарные сравнения всех файлов
    # поэтому нет смысла обрабатывать сложные цепочки похожести и сомнительной
    # похожести.
    doubtful
  end

  def call(data)
    doubtful = find_dups(data)
    # Нужно избежать дублирования записей. Пример
    # dup: /app/video_new/takeout-202306-video/Photos from 2018/VID-20181231-WA0015.mp4
    # len: 57.91, ratio: 1.0
    # dup: /app/video_new/takeout-202306-video/Photos from 2018/VID-20190128-WA0017.mp4
    # len: 59.048, ratio: 1.0, distance: 14

    # dup: /app/video_new/takeout-202306-video/Photos from 2018/VID-20190128-WA0017.mp4
    # len: 59.048, ratio: 1.0
    # dup: /app/video_new/takeout-202306-video/Photos from 2018/VID-20181231-WA0015.mp4
    # len: 57.91, ratio: 1.0, distance: 14
    #
    # Видно, что в этих двух записях идет речь об одних и тех же файлах, но
    # в разном порядке.
    action_groups = {}


    # doubtful_clusters = GroupFNames.new.clusters(doubtful)
    action_groups[:inside_new_doubtful], processed_files = generate_actions(doubtful, data, [])

    error_files = []
    [
      action_groups,
      processed_files,
      error_files,
    ]
  end

  def generate_actions(files, data, already_processed_files)
    actions = []
    processed_files = []
    scanned_files = {}

    files.each do |key, dups|
      if scanned_files[key]
        next
      end

      cluster = dups + [key] - already_processed_files

      # Определить элемент у которого самое большое разрешение
      max_resolution_item = max_dimensions_item(cluster - scanned_files.keys, data)

      # Выбрать файлы с таким же разрешением
      max_resolution_items = same_dimensions_items(max_resolution_item, cluster - scanned_files.keys, data)

      # TODO: актуально только для видео
      # Выбрать файлы с максимальной длиной
      max_length_items = get_max_length_items(max_resolution_items, data)

      # Из файлов с максисмальным разрешением выбираем файл с минимальным
      # размером
      minimal_file = min_size_item(max_length_items, data)

      # Выбрать файлы с таким же размером
      minimal_files = same_size_items(minimal_file, max_length_items, data)

      #  Самый лучший файл - тот который самый старый
      groups_by_mtime = minimal_files.group_by { |file_name| data[file_name][:mtime] }
      oldest_mtime = groups_by_mtime.keys.min
      oldest_files = groups_by_mtime[oldest_mtime]

      # За оригинал примем файл с самым длинным имене файла. Это объясняется тем
      # что если имя файла длиннее, значит оно более информативное и лучше его
      # использовать как оригинал (хотя это не всегда так)
      best = oldest_files.max_by { |file_name| file_name.size }

      cluster.each do |file_name|
        next if scanned_files[file_name]

        next if file_name == best

        scanned_files[key] = true
        scanned_files[file_name] = true
        processed_files << file_name

        actions << {
          type: 'move',
          from: data[file_name].merge(relative_path: file_name.to_s),
          to: { root: @dups_dir, relative_path: File.join('new_inside_doubtful', file_name.to_s) },
          original: data[best].merge(relative_path: best.to_s),
        }

      end
    end

    [actions, processed_files]
  end

  private

  def get_max_length_items(cluster, data)
    # get max
    max_length_item = cluster.max do |file_name1, file_name2|
      file_info1 = data[file_name1]
      file_info2 = data[file_name2]
      file_info1[:video_length].to_f <=> file_info2[:video_length].to_f
    end

    # get all with max
    cluster.select do |file_name|
      file_info = data[file_name]
      file_info[:video_length] == data[max_length_item][:video_length]
    end
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
