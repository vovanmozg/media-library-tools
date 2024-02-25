# frozen_string_literal: true

require './lib/reorganize/to_cmds'

class OperationsConverter
  def initialize(settings: {})
    @settings = {
      data_dir: '/vt/data', # path (inside docker) to directory with application data and cache files
      operations_file: 'operations.json',
      command_file: 'commands.sh.txt'
    }.merge(settings)
  end

  def call
    fn = File.join(@settings[:data_dir], @settings[:operations_file])
    operations = JSON.parse(File.read(fn), symbolize_names: true)

    cmds = ToCmds.new(dirs: @settings, system: @system).process(
      actions_groups: operations
    )

    puts cmds

    File.write(File.join(@settings[:data_dir], @settings[:command_file]), cmds.to_json)

    # File.write('./spec/fixtures/dups_mover/commands.sh.json', cmds.to_json)
    # cmds += ToCmds.new(system: @settings[:system], dirs: @settings).process(
    #   actions_groups: actions,
    #   errors: errors
    # )

    # write_commands_file(cmds)
    cmds
  end

  # def write_commands_file(cmds)
  #   IO.write(
  #     File.join(@dirs[:data_dir], @output_commands_file),
  #     cmds.join("\n"),
  #     external_encoding: Encoding::CP866
  #   )
  # rescue Encoding::UndefinedConversionError => e
  #   LOG.error(e.message.red)
  #   IO.write(
  #     File.join(@dirs[:data_dir], "#{@output_commands_file}.utf8"),
  #     cmds.join("\n")
  #   )
  # end

  def write_data(data)
    IO.write(
      File.join(@dirs[:data_dir], "#{data[:type]}_files.json"),
      JSON.pretty_generate(data)
    )
  end

  private

  def add_errors(errors)
    cmds = []
    unless errors.empty?
      cmds << ''
      cmds << '# ERRORS:'
      cmds += errors
    end
    cmds
  end
end
