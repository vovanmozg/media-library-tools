# frozen_string_literal: true

require 'json'
require './lib/media'

# Преобразует actions в operations. структура actions.json и operations.json
# очень похожа и это может быть слегка избыточным. Главное отличие operations.json
# в том, что он содержит всю неободимую информацию для формирования операций
# с файлами, включая реальные пути к файлам и информацию для комментариев,
# которые сопровождают команды перемещения файлов.
class OperationsMaker
  PATH_REPLACING_DIRS = [:existing_dir, :new_dir, :dups_dir]

  def initialize(settings: {})
    @settings = {
      existing_dir: '/vt/existing', # source path (inside docker) to existing media files
      new_dir: '/vt/new', # source path (inside docker) to new media files
      dups_dir: '/vt/dups', # destination path (inside docker) for dups
      data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
      real_existing_dir: '/vt/existing',
      real_new_dir: '/vt/new',
      real_dups_dir: '/vt/dups',
      actions_file: 'actions.json',
      errors_file: 'errors.json',
      operations_file: 'operations.json',
      inside_new_full_dups: true,
      inside_new_similar: true,
      inside_new_doubtful: true,
      full_dups: true,
      similar: true,
      system: :linux
    }.merge(settings)

    # TODO: validate dirs
    #     raise 'Invalid arguments' unless dirs.values.all? && dirs.size == 7
    validate_dirs!
  end

  def call
    actions = JSON.parse(File.read(File.join(@settings[:data_dir], @settings[:actions_file])), symbolize_names: true)
    errors = File.exist?(File.join(@settings[:data_dir], @settings[:errors_file])) ? JSON.parse(File.read(File.join(@settings[:data_dir], @settings[:errors_file])), symbolize_names: true) : []

    cmds = process(
      actions_groups: actions,
      errors: errors
    )

    cmds = cmds.select { |key, values| values.size > 0 }

    File.write(File.join(@settings[:data_dir], @settings[:operations_file]), cmds.to_json)

    cmds
  end

  private

  def process(actions_groups:, errors: [])
    actions_groups.each do |type, actions|
      actions.each do |action|
        send("handle_#{action[:type]}", action)
      end
    end
  end

  def handle_move(action)
    action[:original][:ratio] = Media.calculate_ratio(action[:original]) if action[:original][:width] && action[:original][:height]
    action[:original][:real_root] = normalize(action[:original][:root])
    action[:from][:ratio] = Media.calculate_ratio(action[:from]) if action[:from][:width] && action[:from][:height]
    action[:from][:real_root] = normalize(action[:from][:root])
    action[:to][:distance] = Phashion.hamming_distance(action[:from][:phash], action[:original][:phash])
    action[:to][:real_root] = @settings[:real_dups_dir]
  end

  def handle_wrong_length(action)
    action[:dup] = {
      real_path: normalize(action[:to])
    }
  end

  def handle_wrong_width_or_height(action)
    action[:dup] = {
      real_path: normalize(action[:to])
    }
  end

  # Так как скрипт работает в докере, то он оперирует с внутренними путями
  # в докере. То есть сгенерированный командный файл нельзя запустить на
  # хосте. Можно было бы переносить файлы прямо в докере, но, предполагаю,
  # это будет достаточно медленно, ведь new_dir и dups_dir - это разные точки
  # монтирования и, наверное, система будет переносить файлы побайтово, что
  # для больших файлов будет выполняться долго. А если переносить файлы на
  # хосте, то система переносит файлы путем изменения записей в таблице файлов
  # TODO: шляпная замена из-за того, что мы не знаем тип каталога, поэтому
  #  есть ограничение, что имена каталогов PATH_REPLACING_DIRS не должны
  #  пересекаться
  #  В action можно дополнительно передавать тип (new, existing, dups), тогда
  #  этот костыль можно будет удалить
  def normalize(root)
    return root if @settings.empty?

    replacements = {
      @settings[:new_dir] => @settings[:real_new_dir],
      @settings[:existing_dir] => @settings[:real_existing_dir],
      @settings[:dups_dir] => @settings[:real_dups_dir]
    }

    real_root = replacements[root]
    return root if real_root.nil?

    # TODO сделать обработку windows путей снаружи этого метода
    # return real_root.gsub('/', '\\') if @settings[:system] == :windows

    real_root
  end

  def validate_dirs!
    return if @settings.empty?

    @settings.slice(*PATH_REPLACING_DIRS).values.combination(2).each do |dir1, dir2|
      raise "Dir #{dir1} contains #{dir2}" if dir1.include?(dir2)
      raise "Dir #{dir2} contains #{dir1}" if dir2.include?(dir1)
    end
  end
end
