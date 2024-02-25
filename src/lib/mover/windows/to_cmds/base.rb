# frozen_string_literal: true

class Mover
  class Commands
    class ToCmds
      class Base
        private

        def handle_move(action)
          from = action[:from][:full_path]
          to = action[:to]
          original = action[:original][:full_path]

          cmds = []

          cmds << ":: original: #{original} #{ToCmds.short_meta(action[:original], system: @system)}"
          cmds << ":: dup: #{ToCmds.short_meta(action[:from], action[:original], system: @system)}"
          # dir_to = normalize(File.dirname(action[:to]))
          dir_to = File.dirname(action[:to])
          cmds += mkdir_win_cmds(dir_to, @dirs[:real_dups_dir])
          cmds << %(move "#{from}" "#{to}")
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
      end
    end
  end
end
