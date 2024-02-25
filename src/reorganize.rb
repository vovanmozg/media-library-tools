# frozen_string_literal: true

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
require './lib/dir_reader'
require './lib/reorganize/process_inside_new_full_dups'
require './lib/reorganize/process_inside_new_similar'
require './lib/reorganize/process_inside_new_doubtful'
require './lib/reorganize/process_full_dups'
require './lib/reorganize/process_similar'
require './lib/reorganize/skip_files'
require './lib/reorganize/to_cmds'
require './lib/reorganize/to_json_cmds'

# For determine type of file
FM = FileMagic.new

class Reorganizer
  def initialize(dirs, system:, use_cache: false, settings: {})
    @dirs = dirs
    @dirs[:real_existing_dir] ||= dirs[:existing_dir]
    @dirs[:real_new_dir] ||= dirs[:new_dir]
    @dirs[:real_dups_dir] ||= dirs[:dups_dir]
    raise 'Invalid arguments' unless dirs.values.all? && dirs.size == 7

    @system = system
    @use_cache = use_cache
    @output_commands_file = @system == 'linux' ? 'commands.sh.txt' : 'commands.bat.txt'
    @dir_reader = DirReader.new(log: LOG)
    @errors = []

    @settings = {
      inside_new_full_dups: true,
      inside_new_similar: true,
      inside_new_doubtful: true,
      full_dups: true,
      similar: true
    }.merge(settings)
  end

  def call
    new_data = parse_new_files(cache: @use_cache)
    existing_data = parse_existing_files(cache: @use_cache)

    cmds = []
    # здесь можем делать с $existing_data и $new_data что хотим

    actions, errors = find_dups(existing_data, new_data)
    ToCmdsJson.new(dirs: @dirs, system: @system).process(
      actions_groups: actions,
      errors:
    )
    cmds += ToCmds.new(dirs: @dirs, system: @system).process(
      actions_groups: actions,
      errors:
    )

    write_actions_file(actions)
    write_errors_file(errors)
    # write_commands_file(cmds)
    cmds
  end

  # def write_commands_file(cmds)
  #   IO.write(
  #     File.join(@dirs[:data_dir], @output_commands_file),
  #     cmds.join("\n"),
  #     external_encoding: Encoding::CP866
  #   )
  # rescue Encoding::UndefinedConversionError => e
  #   LOG.error(e.message.red)
  #   IO.write(
  #     File.join(@dirs[:data_dir], "#{@output_commands_file}.utf8"),
  #     cmds.join("\n")
  #   )
  # end

  def write_data(data)
    IO.write(
      File.join(@dirs[:data_dir], "#{data[:type]}_files.json"),
      JSON.pretty_generate(data)
    )
  end

  def write_actions_file(actions)
    IO.write(
      File.join(@dirs[:data_dir], 'actions.json'),
      JSON.pretty_generate(actions)
    )
  end

  def write_errors_file(errors)
    IO.write(
      File.join(@dirs[:data_dir], 'errors.json'),
      JSON.pretty_generate(errors)
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
    if @settings[:inside_new_full_dups]
      processor = ProcessInsideNewFullDups.new(@dirs[:new_dir], @dirs[:dups_dir], LOG)
      files_to_processing = new_data.except(*skipped_files)
      actions, processed_new_files, error_files = processor.call(files_to_processing)
      all_actions.merge!(actions)
      all_error_files += error_files
    end

    # Поискать очень похожие (distance=0) файлы в папке new
    if @settings[:inside_new_similar]
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files, error_files = ProcessInsideNewSimilar.new(@dirs[:new_dir], @dirs[:dups_dir],
                                                                              @errors).call(files_to_processing)
      all_actions.merge!(actions)
      all_error_files += error_files
    end

    # Поискать похожие (0 < distance < 3) файлы в папке new
    if @settings[:inside_new_doubtful]
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files, error_files = ProcessInsideNewDoubtful.new(@dirs[:new_dir], @dirs[:dups_dir],
                                                                               @errors).call(files_to_processing)
      all_actions.merge!(actions)
      all_error_files += error_files
    end

    # Обработать полные дубликаты из new, которые уже есть в existing
    if @settings[:full_dups]
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, processed_new_files = ProcessFullDups.new(@dirs[:new_dir], @dirs[:existing_dir], @dirs[:dups_dir], LOG).call(
        files_to_processing, existing_data
      )
      all_actions.merge!(actions)
    end

    if @settings[:similar]
      # Обработать файлы из new, очень похожие (hamming distance = 0) на те, которые уже есть в existing
      files_to_processing = files_to_processing.except(*processed_new_files)
      actions, = ProcessSimilar.new(@dirs[:new_dir], @dirs[:existing_dir], @dirs[:dups_dir], LOG).call(
        files_to_processing, existing_data
      )
      all_actions.merge!(actions)
    end

    [all_actions, all_error_files]
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
    @dir_reader.parse_files(dir: @dirs[:existing_dir], type: :existing, data_dir: @dirs[:data_dir], cache:)
  end

  def parse_new_files(cache: false)
    @dir_reader.parse_files(dir: @dirs[:new_dir], type: :new, data_dir: @dirs[:data_dir], cache:)
  end
end
