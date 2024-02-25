require './lib/mover/short_meta'

class Mover
  class Linux
    module HandleMove
      def handle_move(action)
        from = File.join(action[:from][:real_root], action[:from][:relative_path])
        to = File.join(action[:to][:real_root], action[:to][:relative_path])
        original = File.join(action[:original][:real_root], action[:original][:relative_path])
        cmds = []
        cmds << "# original: #{original} #{ShortMeta.new.short_meta(action[:original])}"
        cmds << "# dup: #{ShortMeta.new.short_meta(action[:from], action[:to])}"
        cmds << "mkdir -p '#{File.dirname(File.join(action[:to][:real_root], action[:to][:relative_path]))}'"
        cmds << "mv '#{from}' '#{to}'"
        cmds << ''

        cmds
      end
    end
  end
end
