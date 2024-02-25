class Mover
  class Linux
    class ToCmds
      class Base < Mover::Commands::ToCmds::Base


        private



        def mkdir_win_cmds(dir, real_dir)
          cmds = []
          relative = dir.gsub(real_dir, '').split('\\')[1..-1]
          path = real_dir
          relative.each do |dir|
            path = File.join(path, dir).gsub('/', '\\')
            cmds << %Q(if not exist "#{path}" mkdir "#{path}")
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
        # def normalize2(path)
        #   return path if @dirs.empty?
        #
        #   is_changed = false
        #
        #   path = path.to_s
        #   if @dirs[:new_dir] && @dirs[:real_new_dir] && @dirs[:new_dir] != @dirs[:real_new_dir]
        #     path = path.gsub(%r{\A#{@dirs[:new_dir]}}, @dirs[:real_new_dir])
        #     is_changed = true
        #   end
        #
        #   if @dirs[:existing_dir] && @dirs[:real_existing_dir] && @dirs[:existing_dir] != @dirs[:real_existing_dir]
        #     path = path.gsub(@dirs[:existing_dir], @dirs[:real_existing_dir])
        #     is_changed = true
        #   end
        #
        #   if @dirs[:dups_dir] && @dirs[:real_dups_dir] && @dirs[:dups_dir] != @dirs[:real_dups_dir]
        #     path = path.gsub(@dirs[:dups_dir], @dirs[:real_dups_dir])
        #     is_changed = true
        #   end
        #
        #   if is_changed && @system == :windows
        #     path.gsub('/', '\\')
        #   else
        #     path
        #   end
        # end
      end
    end
  end
end
