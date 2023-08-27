require './lib/media'
require './lib/reorganize/to_cmds/base'
require './lib/reorganize/to_cmds/skipped'
require './lib/reorganize/to_cmds/inside_new_full_dups'
require './lib/reorganize/to_cmds/inside_new_similar'
require './lib/reorganize/to_cmds/inside_new_doubtful'
require './lib/reorganize/to_cmds/new_full_dups'
require './lib/reorganize/to_cmds/new_similar'

class ToCmds
  PATH_REPLACING_DIRS = [:existing_dir, :new_dir, :dups_dir]

  def initialize(system:, dirs: {})
    @system = system
    @dirs = dirs
    validate_dirs!
    # @new_real_root = '/vt/new'
    # @existing_real_root = '/vt/existing'
    # @dups_real_root = '/vt/dups'
  end

  # Example of input (TODO: not actual comment)
  #   "inside_new_full_dups" => [
  #     {
  #       "type" => "move",
  #       "from" => "/vt/new/1.mp4",
  #       "to" => "/vt/dups/new_inside_full_dups/1.mp4",
  #       "dups" => [
  #         "/vt/new/1.mp4",
  #         "/vt/new/1 identical.mp4"
  #       ],
  #       "original" => "/vt/new/1 identical.mp4"
  #     }
  #   ]
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
      converter = klass.new(system: @system, dirs: @dirs)
      cmds += converter.call(actions)
    end
    cmds
  end

  def comment
    @system == :linux ? '#' : '::'
  end

  def validate_dirs!
    return if @dirs.empty?

    @dirs.slice(*PATH_REPLACING_DIRS).values.combination(2).each do |dir1, dir2|
      raise "Dir #{dir1} contains #{dir2}" if dir1.include?(dir2)
      raise "Dir #{dir2} contains #{dir1}" if dir2.include?(dir1)
    end
  end

  # Формирует строку с метаинформацией о файле: длина, соотношение сторон, размеры
  def self.short_meta(file_info, file_info_original = nil, system: )
    output = []

    len = file_info[:video_length]
    output << "len: #{len}" if len

    w = file_info[:width]
    h = file_info[:height]
    size = file_info[:size]
    if w && h
      ratio = Media.calculate_ratio(file_info)
      output << "#{w}x#{h} (ratio #{ratio}), size: #{size}"
    else
      # @errors << "# No width/height for #{fn1}"
    end

    if file_info_original
      distance = Phashion.hamming_distance(file_info[:phash], file_info_original[:phash])
      output << "distance: #{distance}"
    end

    output << "#{Time.at(file_info[:mtime]).strftime('%Y-%m-%d %H:%M:%S')}"
    output.join(', ')
  end
end
