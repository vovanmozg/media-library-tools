# frozen_string_literal: true

# Читает мету из файлов existing_files.json и new_files.json
# Ищет дубликаты
# Сохраняет результат в файл actions.json и errors.json

# Если есть одинаковые файлы в папке new_files, то
#   Если файлы идентичные (по md5), то оставляем файл с самым длинным именем.
#     Остальные переносим в папку new_inside_full_dups
# Если найден дубликат
#   Если новый файл имеет большее разрешение, то перемещаем его в папку
#     new_higher_resolution, старый перемещаем в папку existing_lower_resolution
#   Если новый файл имеет меньшее разрешение, то перемещаем его в папку dups
#   Если новый файл имеет такое же разрешение, но меньше по размеру, то
#     перемещаем его в папку new_better_compressed, старый перемещаем в
#     папку existing_worse_compressed
# Если не удалось посчитать phash у файла, то считаем, что этот файл проблемный
#   и перемещаем его в папку new_problematic

require './lib/comparator/process_inside_new_full_dups'
require './lib/comparator/process_inside_new_similar'
require './lib/comparator/process_inside_new_doubtful'
require './lib/comparator/process_full_dups'
require './lib/comparator/process_similar'
require './lib/comparator/skip_files'
require './lib/dir_reader'

class Comparator
  def initialize(settings: {})
    @dir_reader = DirReader.new(log: LOG)
    @errors = []
    @settings = {
      existing_dir: '/vt/existing', # source path (inside docker) to existing media files
      new_dir: '/vt/new', # source path (inside docker) to new media files
      dups_dir: '/vt/dups', # destination path (inside docker) for dups
      data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
      real_existing_dir: '/vt/existing',
      real_new_dir: '/vt/new',
      real_dups_dir: '/vt/dups',
      inside_new_full_dups: true, # is it needed to process files inside new dir, which are full dups
      inside_new_similar: true, # is it needed to process files inside new dir, which are similar
      inside_new_doubtful: true, # is it needed to process files inside new dir, which are doubtful similar
      full_dups: true, # is it needed to process files from new dir, which are full dups of existing files
      similar: true, # is it needed to process files from new dir, which are similar to existing files
      show_skipped: true,
      actions_path: 'actions.json', # relative path from data_dir
      errors_path: 'errors.json', # relative path from data_dir
      existing_meta_file: 'files_existing.json', # relative path from data_dir
      new_meta_file: 'files_new.json', # relative path from data_dir
    }.merge(settings)
    p @settings
  end

  def call
    if File.exists? @settings[:existing_meta_file]
      existing_data = @dir_reader.read_cache(File.join(@settings[:data_dir], @settings[:existing_meta_file]))
    else
      existing_data = {}
    end

    new_data = @dir_reader.read_cache(File.join(@settings[:data_dir], @settings[:new_meta_file]))

    actions, errors = find_dups(existing_data, new_data)

    write_actions_file(actions)
    write_errors_file(errors)
    nil
  end

  def write_actions_file(actions)
    IO.write(
      File.join(@settings[:data_dir], @settings[:actions_path]),
      JSON.pretty_generate(actions)
    )
  end

  def write_errors_file(errors)
    IO.write(
      File.join(@settings[:data_dir], @settings[:errors_path]),
      JSON.pretty_generate(errors)
    )
  end

  def find_dups(existing_data, new_data)
    all_actions = {}
    all_error_files = []

    # Сначала проверим, нет ли битых файлов в папке new
    files_to_processing = new_data
    processor = SkipFiles.new(@settings[:new_dir], @settings[:dups_dir])
    skipped_files, actions = processor.call(files_to_processing)
    all_actions.merge!(actions) if @settings[:show_skipped]

    # Проверить, нет ли идентичных дубликатов в папке new (по частичному md5)
    # TODO: Возможно найденные на этом этапе файлы стоит дополнительно сравнить
    #  побайтово
    if @settings[:inside_new_full_dups]
      processor = ProcessInsideNewFullDups.new(@settings[:new_dir], @settings[:dups_dir], LOG)
      files_to_processing = new_data.except(*skipped_files)
      actions, processed_new_files, error_files = processor.call(files_to_processing)
      all_actions.merge!(actions)
      all_error_files += error_files
    end

      # Поискать очень похожие (distance=0) файлы в папке new
    if @settings[:inside_new_similar]
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files, error_files = ProcessInsideNewSimilar.new(@settings[:new_dir], @settings[:dups_dir], @errors).call(files_to_processing)
      all_actions.merge!(actions)
      all_error_files += error_files
    end

    # Поискать похожие (0 < distance < 3) файлы в папке new
    if @settings[:inside_new_doubtful]
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files, error_files = ProcessInsideNewDoubtful.new(@settings[:new_dir], @settings[:dups_dir], @errors).call(files_to_processing)
      all_actions.merge!(actions)
      all_error_files += error_files
    end

    # Обработать полные дубликаты из new, которые уже есть в existing
    if @settings[:full_dups]
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files = ProcessFullDups.new(@settings[:new_dir], @settings[:existing_dir], @settings[:dups_dir], LOG).call(files_to_processing, existing_data)
      all_actions.merge!(actions)
    end

    if @settings[:similar]
      # Обработать файлы из new, очень похожие (hamming distance = 0) на те, которые уже есть в existing
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files = ProcessSimilar.new(@settings[:new_dir], @settings[:existing_dir], @settings[:dups_dir], LOG).call(files_to_processing, existing_data)
      all_actions.merge!(actions)
    end

    [all_actions, all_error_files]
  end

  private

  def read_existing_files
    @dir_reader.read_cache(type: :existing, data_dir: @settings[:data_dir])
  end

  def read_new_files
    @dir_reader.read_cache(type: :new, data_dir: @settings[:data_dir])
  end
end
