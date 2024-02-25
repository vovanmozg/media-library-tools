# frozen_string_literal: true

require 'json'

require_relative 'mover/linux'
require_relative 'mover/windows'
require_relative 'mover/immediately'
require_relative 'mover/linux/inside_new_doubtful'
require_relative 'mover/linux/inside_new_full_dups'
require_relative 'mover/linux/inside_new_similar'
require_relative 'mover/linux/full_dups'
require_relative 'mover/linux/similar'

class Mover
  PATH_REPLACING_DIRS = %i[existing_dir new_dir dups_dir].freeze

  def initialize(settings: {})
    @settings = {
      operations_file: 'operations.json',
      commands_file: 'commands.sh.txt',
      data_dir: '/vt/data',
      driver_type: :linux
    }.merge(settings)

    @driver_type = {
      linux: Linux,
      windows: Windows,
      immediately: Immediately
    }.fetch(@settings[:driver_type]) { raise "Unknown mover type: #{@driver_type}" }

    validate_dirs!
  end

  def call(operations: nil, errors: [])
    cmds = []
    if operations.nil?
      operations = JSON.parse(File.read(File.join(@settings[:data_dir], @settings[:operations_file])),
                              symbolize_names: true)
    end

    cmds += @driver_type.headers(operations)

    operations.each do |type, actions|
      next if type == :skipped

      # Формируем класс в виде Mover::Linux::InsideNewDoubtful
      name = "#{@driver_type}::#{type.to_s.split('_').map(&:capitalize).join('')}"
      klass = Mover.const_get(name)
      converter = klass.new

      cmds += converter.header

      actions.each do |action|
        cmds += converter.send("handle_#{action[:type]}", action)
      end
    end

    File.write(File.join(@settings[:data_dir], @settings[:commands_file]), cmds.join("\n"))

    cmds
  end

  def validate_dirs!
    return if @settings.empty?

    @settings.slice(*PATH_REPLACING_DIRS).values.combination(2).each do |dir1, dir2|
      raise "Dir #{dir1} contains #{dir2}" if dir1.include?(dir2)
      raise "Dir #{dir2} contains #{dir1}" if dir2.include?(dir1)
    end
  end
end
