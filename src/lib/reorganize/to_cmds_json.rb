require './lib/media'

class ToCmdsJson
  PATH_REPLACING_DIRS = [:existing_dir, :new_dir, :dups_dir]

  def initialize(system:, dirs: {})
    @system = system
    @dirs = dirs
    validate_dirs!
  end

  def process(actions_groups:, errors: [])
    actions_groups.each do |type, actions|
      process_all(actions)
    end
  end

  private

  def process_all(actions)
    actions.each do |action|
      send("handle_#{action[:type]}", action)
    end
  end

  def handle_move(action)
    action[:original][:real_path] = normalize(action[:original][:full_path])
    action[:original].merge!(ToCmdsJson.original_meta(action[:original], system: @system))
    action[:dup] = ToCmdsJson.dup_meta(action[:from], action[:original], system: @system)
    action[:dup][:real_path] = normalize(action[:to])
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
  def normalize(path)
    return path if @dirs.empty?

    is_changed = false

    if @dirs[:new_dir] && @dirs[:real_new_dir] && @dirs[:new_dir] != @dirs[:real_new_dir]
      path = path.gsub(%r{\A#{@dirs[:new_dir]}}, @dirs[:real_new_dir])
      is_changed = true
    end

    if @dirs[:existing_dir] && @dirs[:real_existing_dir] && @dirs[:existing_dir] != @dirs[:real_existing_dir]
      path = path.gsub(@dirs[:existing_dir], @dirs[:real_existing_dir])
      is_changed = true
    end

    if @dirs[:dups_dir] && @dirs[:real_dups_dir] && @dirs[:dups_dir] != @dirs[:real_dups_dir]
      path = path.gsub(@dirs[:dups_dir], @dirs[:real_dups_dir])
      is_changed = true
    end

    if is_changed && @system == :windows
      path.gsub('/', '\\')
    else
      path
    end
  end

  def validate_dirs!
    return if @dirs.empty?

    @dirs.slice(*PATH_REPLACING_DIRS).values.combination(2).each do |dir1, dir2|
      raise "Dir #{dir1} contains #{dir2}" if dir1.include?(dir2)
      raise "Dir #{dir2} contains #{dir1}" if dir2.include?(dir1)
    end
  end

  # Формирует строку с метаинформацией о файле: длина, соотношение сторон, размеры
  def self.original_meta(file_info, system: )
    output = {}
    output[:date] = "#{Time.at(file_info[:mtime]).strftime('%Y-%m-%d %H:%M:%S')}"
    output[:ratio] = Media.calculate_ratio(file_info) if file_info[:width] && file_info[:height]
    output
  end

  def self.dup_meta(file_info, file_info_original, system: )
    output = {}
    output[:distance] = Phashion.hamming_distance(file_info[:phash], file_info_original[:phash])
    output[:date] = "#{Time.at(file_info[:mtime]).strftime('%Y-%m-%d %H:%M:%S')}"
    output[:ratio] = Media.calculate_ratio(file_info) if file_info[:width] && file_info[:height]
    output
  end
end
