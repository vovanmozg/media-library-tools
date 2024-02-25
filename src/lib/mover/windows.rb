class Mover::Windows
  def self.headers(actions_groups)
    cmds = []
    ## Add summary
    cmds << "#{comment} Summary:"
    cmds << "#{comment}   Identical files inside new dir: #{actions_groups[:inside_new_full_dups]&.size || 0}"
    cmds << "#{comment}   Similar files inside new dir: #{actions_groups[:inside_new_similar]&.size || 0}"
    cmds << "#{comment}   Doubtful similar files inside new dir: #{actions_groups[:inside_new_doubtful]&.size || 0}"
    cmds << "#{comment}   Files in new identical to existing: #{actions_groups[:full_dups]&.size || 0}"
    cmds << "#{comment}   Files in new similar to existing: #{actions_groups[:similar]&.size || 0}"
    cmds << "#{comment}   Broken files: #{actions_groups[:skipped]&.size || 0}"
    cmds << "#{comment}   total: #{actions_groups.values.flatten.size || 0}"
    cmds << "#{comment}"
  end

  def self.comment
    '::'
  end
end
