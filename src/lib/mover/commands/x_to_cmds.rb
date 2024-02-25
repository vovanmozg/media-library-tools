require './lib/media'
require './lib/reorganize/to_cmds/base'
require './lib/reorganize/to_cmds/skipped'
require './lib/reorganize/to_cmds/inside_new_full_dups'
require './lib/reorganize/to_cmds/inside_new_similar'
require './lib/reorganize/to_cmds/inside_new_doubtful'
require './lib/reorganize/to_cmds/new_full_dups'
require './lib/reorganize/to_cmds/new_similar'

class XToCmds
  PATH_REPLACING_DIRS = [:existing_dir, :new_dir, :dups_dir]

  def initialize(settings)
    @settings = settings

    validate_dirs!
  end

  def process(actions_groups:, errors: [])
    cmds = []
    ## Add summary
    cmds << "#{comment} Summary:"
    cmds << "#{comment}   Identical files inside new dir: #{actions_groups[:inside_new_full_dups]&.size || 0}"
    cmds << "#{comment}   Similar files inside new dir: #{actions_groups[:inside_new_similar]&.size || 0}"
    cmds << "#{comment}   Doubtful similar files inside new dir: #{actions_groups[:inside_new_doubtful]&.size || 0}"
    cmds << "#{comment}   Files in new identical to existing: #{actions_groups[:new_full_dups]&.size || 0}"
    cmds << "#{comment}   Files in new similar to existing: #{actions_groups[:new_similar]&.size || 0}"
    cmds << "#{comment}   Broken files: #{actions_groups[:skipped]&.size || 0}"
    cmds << "#{comment}   total: #{actions_groups.values.flatten.size || 0}"
    cmds << "#{comment}"

    actions_groups.each do |type, actions|
      name = "ToCmds::#{type.to_s.split('_').map(&:capitalize).join('')}"
      klass = ToCmds.const_get(name)
      converter = klass.new(settings: @settings)
      cmds += converter.call(actions)
    end
    cmds
  end

  def comment
    raise "Not implemented"
    # @settings[:system] == :linux ? '#' : '::'
  end

  def validate_dirs!
    return if @settings.empty?

    @settings.slice(*PATH_REPLACING_DIRS).values.combination(2).each do |dir1, dir2|
      raise "Dir #{dir1} contains #{dir2}" if dir1.include?(dir2)
      raise "Dir #{dir2} contains #{dir1}" if dir2.include?(dir1)
    end
  end

end
