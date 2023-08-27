class ToCmds
  class Skipped < Base
    def header_title
      'Broken files'
    end

    def handle_wrong_length(action)
      cmds = []
      from = action[:from]
      to = action[:to]
      if @system == :linux
        cmds << "# #{from}, wrong length: #{action[:file_info][:size]}"
        dir_to = normalize(File.dirname(to))
        cmds << %Q(mkdir -p "#{dir_to}")
        cmds << %Q(mv "#{from}" "#{to}")
      else
        cmds << ":: #{from}, wrong length: #{action[:file_info][:size]}"
        dir_to = normalize(File.dirname(to))
        cmds += mkdir_win_cmds(dir_to, @dirs[:real_dups_dir])
        cmds << %Q(move '#{from}' "#{to}")
      end
      cmds << ''
      cmds
    end

    def handle_wrong_width_or_height(action)
      cmds = []
      from = normalize(action[:from])
      to = normalize(action[:to])
      if @system == :linux
        cmds << "# #{from}, wrong dimensions: #{action[:file_info][:width]}x#{action[:file_info][:height]}"
        dir_to = normalize(File.dirname(to))
        cmds << %Q(mkdir -p "#{dir_to}")
        cmds << %Q(mv "#{from}" "#{to}")
      else
        cmds << ":: #{from}, wrong dimensions: #{action[:file_info][:width]}x#{action[:file_info][:height]}"
        dir_to = normalize(File.dirname(action[:to]))
        cmds += mkdir_win_cmds(dir_to, @dirs[:real_dups_dir])
        cmds << %Q(move "#{from}" "#{to}")
      end
      cmds << ''
      cmds
    end
  end
end
