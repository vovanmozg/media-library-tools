# Сканирует папку с уже существующими файлами
# Сканирует папку с новыми файлами
# Создает bash-файл на перемещение файлов
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

require 'active_support/core_ext/hash/indifferent_access'
require 'awesome_print'
require 'filemagic'
require 'pry-byebug'
require './lib/phash'
require './lib/cache'
require './lib/scan_files'
require './lib/log'
require './lib/media'
require './lib/reorganize/process_inside_new_full_dups'
require './lib/reorganize/process_inside_new_similar'
require './lib/reorganize/process_inside_new_doubtful'
require './lib/reorganize/process_full_dups'
require './lib/reorganize/process_similar'
require './lib/reorganize/skip_files'
require './lib/reorganize/to_cmds'
require './lib/utils'

# For determine type of file
FM = FileMagic.new

class Reorganizer
  def initialize(dirs, use_cache: false, system:)
    @dirs = dirs
    @dirs[:real_existing_dir] ||= dirs[:existing_dir]
    @dirs[:real_new_dir] ||= dirs[:new_dir]
    @dirs[:real_dups_dir] ||= dirs[:dups_dir]
    raise 'Invalid arguments' unless dirs.values.all? && dirs.size == 7

    @system = system
    @use_cache = use_cache
    @output_commands_file = @system == 'linux' ? 'commands.sh.txt' : 'commands.bat.txt'
    @media = Media.new(dirs[:cache_dir], LOG)
    @errors = []
  end

  def call
    new_data = parse_new_files(cache: @use_cache)
    existing_data = parse_existing_files(cache: @use_cache)
    cmds = []
    # здесь можем делать с $existing_data и $new_data что хотим

    actions, errors = find_dups(existing_data, new_data)
    cmds += ToCmds.new(dirs: @dirs, system: @system).process(
      actions_groups: actions,
      errors: errors
    )

    write_commands_file(cmds)
    cmds
  end

  def write_commands_file(cmds)
    IO.write(
      File.join(@dirs[:dups_dir], @output_commands_file),
      cmds.join("\n"),
      external_encoding: Encoding::CP866
    )
  rescue Encoding::UndefinedConversionError => e
    LOG.error(e.message.red)
    IO.write(
      File.join(@dirs[:dups_dir], "#{@output_commands_file}.utf8"),
      cmds.join("\n")
    )
  end

  def find_dups(existing_data, new_data)
    all_actions = {}
    all_error_files = []

    # Сначала проверим, нет ли битых файлов в папке new
    files_to_processing = new_data
    processor = SkipFiles.new(@dirs[:new_dir], @dirs[:dups_dir])
    skipped_files, actions = processor.call(files_to_processing)
    all_actions.merge!(actions)

    # Проверить, нет ли идентичных дубликатов в папке new (по частичному md5)
    # TODO: Возможно найденные на этом этапе файлы стоит дополнительно сравнить
    #  побайтово
    processor = ProcessInsideNewFullDups.new(@dirs[:new_dir], @dirs[:dups_dir], LOG)
    files_to_processing = new_data.except(*skipped_files)
    actions, processed_new_files, error_files = processor.call(files_to_processing)
    all_actions.merge!(actions)
    all_error_files += error_files

    # Поискать очень похожие (distance=0) файлы в папке new
    files_to_processing = files_to_processing.except(*processed_new_files)
    actions, processed_new_files, error_files = ProcessInsideNewSimilar.new(@dirs[:new_dir], @dirs[:dups_dir], @errors).call(files_to_processing)
    all_actions.merge!(actions)
    all_error_files += error_files

    # Поискать похожие (0 < distance < 3) файлы в папке new
    files_to_processing = files_to_processing.except(*processed_new_files)
    actions, processed_new_files, error_files = ProcessInsideNewDoubtful.new(@dirs[:new_dir], @dirs[:dups_dir], @errors).call(files_to_processing)
    all_actions.merge!(actions)
    all_error_files += error_files

    # Обработать полные дубликаты из new, которые уже есть в existing
    files_to_processing = files_to_processing.except(*processed_new_files)
    actions, processed_new_files = ProcessFullDups.new(@dirs[:new_dir], @dirs[:existing_dir], @dirs[:dups_dir], LOG).call(files_to_processing, existing_data)
    all_actions.merge!(actions)

    # Обработать файлы из new, очень похожие (hamming distance = 0) на те, которые уже есть в existing
    files_to_processing = files_to_processing.except(*processed_new_files)
    actions, processed_new_files = ProcessSimilar.new(@dirs[:new_dir], @dirs[:existing_dir], @dirs[:dups_dir], LOG).call(files_to_processing, existing_data)
    all_actions.merge!(actions)

    [all_actions, all_error_files]
  end

  # @return [Hash] key - full path to file, value - hash with file info
  #
  #   Example of return Hash with one key
  #   {
  #   "/app/video_existing/2019-wa/20181201-WA0007 fotomama.mp4": {
  #     "video_length": 180.86,
  #     "phash": 15591569520836312423,
  #     "width": 400,
  #     "height": 400,
  #     "partial_md5": "100eaca7339bfbabbf3b9e4b1e51542a",
  #     "size": 7406817,
  #     "name": "20181201-WA0007 fotomama.mp4",
  #     "id": "100eaca7339bfbabbf3b9e4b1e51542a 7406817 20181201-WA0007 fotomama.mp4"
  #   },
  # Если в папке произошли изменения, то нужно руками удалить файл existing_files.json
  # Дело в том, что после того, как скрипт прочитает все файлы, он запишет
  # результирующий объект в этот файл. И при следующем запуске, скрипт не будет
  # снова читать файлы, а просто возьмет закешированные данные. Поэтому если,
  # например, какой-то файл будет удален, то скрипт не узнает об этом и будет
  # думать, что этот файл есть. Этот файл будет участововать при поиске дублей
  # $current_type = :existing
  def parse_files(type, dir, cache: false)
    data = nil
    counters = Counters.new(type, @dirs[:cache_dir])

    json_file = File.join(@dirs[:cache_dir], "#{type}_files.json")
    if cache && File.exist?(json_file)
      data = read_hash(json_file)
      counters.increase(:from_cache)
    end

    unless data
      data = {}
      scan_files(dir, LOG) do |file_name|
        if LOG.level == Logger::INFO
          print '.'
        end
        file_info = @media.read_file!(file_name, FM)
        data[file_name] = file_info if file_info
      end

      if cache
        IO.write(json_file, JSON.pretty_generate(data))
      end
    end

    data.tap { |data| validate_values!(data) }
  end

  private

  def add_errors(errors)
    cmds = []
    unless errors.empty?
      cmds << ''
      cmds << '# ERRORS:'
      cmds += errors
    end
    cmds
  end

  def parse_existing_files(cache: false)
    parse_files(:existing, @dirs[:existing_dir], cache: cache)
  end

  def parse_new_files(cache: false)
    parse_files(:new, @dirs[:new_dir], cache: cache)
  end

  def validate_values!(data)
    data.each_value do |file_info|
      missing = InvalidateCache.new.find_missing_attributes(file_info, file_info[:type])
      unless missing.empty?
        raise "Missing attributes #{missing}"
      end
    end
  end
end
