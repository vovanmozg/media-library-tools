# frozen_string_literal: true

class Mover
  class Commands
    class ToCmds
      class XBase
        def initialize(settings: {})
          @system = settings[:system]
          @dirs = settings
        end

        def call(actions)
          cmds = []

          actions.each do |action|
            cmds += send("handle_#{action[:type]}", action)
          end

          cmds.empty? ? [] : header + cmds
        end

        private

        def header
          [
            "#{comment} #{'#' * (header_title.length + 4)}",
            "#{comment} # #{header_title} #",
            "#{comment} #{'#' * (header_title.length + 4)}"
          ]
        end
      end
    end
  end
end

class ToCmds
  class Base
    def handle_move(action)
      from = action[:from][:full_path]
      to = action[:to]
      original = action[:original][:full_path]

      cmds = []

      if @system == :linux
        cmds << "# original: #{original} #{ToCmds.short_meta(action[:original], system: @system)}"
        cmds << "# dup: #{ToCmds.short_meta(action[:from], action[:original], system: @system)}"
        cmds << "mkdir -p '#{File.dirname(to)}'"
        cmds << "mv '#{from}' '#{to}'"
      else
        cmds << ":: original: #{original} #{ToCmds.short_meta(action[:original], system: @system)}"
        cmds << ":: dup: #{ToCmds.short_meta(action[:from], action[:original], system: @system)}"
        # dir_to = normalize(File.dirname(action[:to]))
        dir_to = File.dirname(action[:to])
        cmds += mkdir_win_cmds(dir_to, @dirs[:real_dups_dir])
        cmds << %(move "#{from}" "#{to}")
      end
      cmds << ''
      cmds
    end

    def mkdir_win_cmds(dir, real_dir)
      cmds = []
      relative = dir.gsub(real_dir, '').split('\\')[1..]
      path = real_dir
      relative.each do |dir|
        path = File.join(path, dir).gsub('/', '\\')
        cmds << %(if not exist "#{path}" mkdir "#{path}")
      end
      cmds
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
    def normalize2(path)
      return path if @dirs.empty?

      is_changed = false

      path = path.to_s
      if @dirs[:new_dir] && @dirs[:real_new_dir] && @dirs[:new_dir] != @dirs[:real_new_dir]
        path = path.gsub(/\A#{@dirs[:new_dir]}/, @dirs[:real_new_dir])
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
  end
end
