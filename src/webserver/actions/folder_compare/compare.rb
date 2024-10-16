# frozen_string_literal: true

require 'string_to_id'
require './lib/batch_move'
require './config/constants'
require './meta_reader'
require './comparator'

class InvalidParamsError < StandardError; end

# Ключевые параметры при использовании класса
# steps - массив шагов, которые нужно выполнить. Возможные значения:
#   read_meta - считать метаданные
#   compare - сравнить
#   make_operations - сформировать операции
#   move - переместить
# actions - массив типов сравнений. Возможные значения:
#   inside_new_full_dups
#   inside_new_similar
#   inside_new_doubtful
#   full_dups
#   similar
#
class FolderCompare
  class Compare
    # { "dir_new" => "/vt",
    #   "dir_real_new" => "",
    #   "dir_original" => "/vt",
    #   "dir_real_original" => "",
    #   "compare_types" => ["full_dups"],
    #   "steps" => ["read_meta", "compare", "make_operations", "move"],
    #   "media_meta_path" => "" }

    def initialize(settings)
      @settings = {
        data_dir: '/vt/data',
        dups_dir: '/vt/dups'
      }.merge(settings)
    end

    def call
      # Thread.new do
      process
      # end
    end

    def new_meta_file_path
      "files_new_#{@suffix}.json"
    end

    def process
      validate_steps

      @suffix = StringToId.string_to_id("#{Time.now.strftime('%Y-%m-%d_%H-%M')}_#{@settings[:new_dir]}_#{@settings[:existing_dir]}")

      if @settings[:steps].include?('read_meta')
        read_meta('existing') if existing_dir_used?
        read_meta('new')
      end

      return unless @settings[:steps].include?('compare')

      compare

      # make_operations
      # move

      {
        new_meta_file: new_meta_file_path
      }
    end

    private

    def read_meta(type)
      MetaReader.new(
        media_dir: @settings["#{type}_dir".to_sym],
        media_meta_path: "files_#{type}_#{@suffix}.json"
      ).call
    end

    def compare
      @settings[:steps] = @settings[:steps].map { |step| [step, true] }.to_h

      # Compare meta
      comparator = Comparator.new(
        settings: {
          existing_dir: @settings[:existing_dir],
          new_dir: @settings[:new_dir],
          inside_new_full_dups: @settings[:actions].include?('inside_new_full_dups'),
          inside_new_similar: @settings[:actions].include?('inside_new_similar'),
          inside_new_doubtful: @settings[:actions].include?('inside_new_doubtful'),
          full_dups: @settings[:actions].include?('full_dups'),
          similar: @settings[:actions].include?('similar'),
          show_skipped: @settings[:actions].include?('show_skipped'),
          actions_file: "actions_#{@suffix}.json",
          new_meta_file: new_meta_file_path,
          existing_meta_file: "files_existing_#{@suffix}.json"

          #             --inside_new_full_dups=true \
          #             --full_dups=false \
          #             --inside_new_similar=false \
          #             --inside_new_doubtful=false \
          #             --similar=false \
          #             --show_skipped=false \
          #             --new_meta_file=files_new_$DIR.json \
          #             --actions_path=actions_$DIR.json
        }
      )
      comparator.call
    end

    def make_operations
      # Prepare operations in json format. This step contains real paths
      #  replacement

      OperationsMaker.new(
        settings: {
          real_existing_dir: @settings[:real_existing_dir],
          real_new_dir: @settings[:real_new_dir],
          real_dups_dir: @settings[:real_dups_dir],
          actions_file: "actions_#{@suffix}.json",
          operations_file: "operations_#{@suffix}.json"
        }
      ).call
    end

    def move
      # Generate bahs-file to move files
      mover = Mover.new(
        settings: {
          operations_file: "operations_#{@suffix}.json",
          commands_file: "commands_#{@suffix}.sh.txt",
          driver_type: :linux
        })

      mover.call
    end

    def existing_dir_used?
      !!(@settings[:full_dups] || @settings[:similar])
    end

    def validate_steps
      raise InvalidParamsError, "Invalid data_dir: #{@settings[:data_dir]}" unless File.directory?(@settings[:data_dir])

      ap @settings

      if existing_dir_used?
        validate_dir(@settings[:existing_dir], :existing_dir)
      else
        if @settings[:existing_dir]
          raise InvalidParamsError, 'You should not specify existing dir if you do not use it'
        end
      end
      validate_dir(@settings[:new_dir], :new_dir)

      if existing_dir_used? && @settings[:existing_dir] == @settings[:new_dir]
        raise InvalidParamsError,
              'New dir and existing dir must be different'
      end

      if existing_dir_used? && @settings[:existing_dir].include?(@settings[:new_dir])
        raise InvalidParamsError,
              'New dir must not be part of existing dir'
      end

      if existing_dir_used? && @settings[:new_dir].include?(@settings[:existing_dir])
        raise InvalidParamsError,
              'Existing dir must not be part of new dir'
      end

      if @settings[:steps].include?('compare')
        # validate_dir(@settings[:existing_dir], :existing_dir)
        # validate_dir(@settings[:new_dir], :new_dir)
        validate_dir(@settings[:dups_dir], :dups_dir)
      end

      return unless @settings[:steps].include?('make_operations')

      # validate_dir(@settings[:existing_dir], :existing_dir)
      # validate_dir(@settings[:new_dir], :new_dir)
      validate_dir(@settings[:dups_dir], :dups_dir)
      validate_real_dir(@settings[:real_existing_dir], :real_existing_dir)
      validate_real_dir(@settings[:real_new_dir], :real_new_dir)
      validate_real_dir(@settings[:real_dups_dir], :real_dups_dir)
    end

    def validate_dir(dir, type)
      return unless dir.nil? || dir.empty? || !File.directory?(dir)

      raise InvalidParamsError, "Invalid #{type}: #{dir}"
    end

    def validate_real_dir(dir, type)
      return unless dir.nil? || dir.empty?

      raise InvalidParamsError, "Invalid #{type}: #{dir}"
    end

    def save_log(results)
      log_file_name = File.join(CONFIG[:data_dir_path], 'move.log')
      File.touch(log_file_name) unless File.exist?(log_file_name)
      open(log_file_name, 'a') do |f|
        f.puts results.map { |line| "#{Time.now.strftime('%Y-%m-%d %H-%M-%S')} #{line}" }.join("\n")
      end
    end
  end
end
