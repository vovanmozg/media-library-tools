# frozen_string_literal: true

class SortBatchMove
  FM = FileMagic.new
  OPERATION_MAP = {
    'foto' => 'foto',
    'fotoother' => 'fotoother',
    'nofoto' => 'nofoto',
    'health' => 'nofoto/здоровье',
    'documents' => 'nofoto/documents',
    'alien' => 'alien',
    'archive' => 'archive',
    'non-sorted' => 'non-sorted'
  }.freeze

  def call(moving_actions, config)
    @config = config
    results = []

    moving_actions.each do |file_name, action|
      results << handle_file_deletion(file_name, action)
    end

    results
  end

  private

  def prepare_operations(action, item)
    operations = []

    if OPERATION_MAP[action][:original]
      operations << { source: item['original']['full_path'], action: 'original',
                      destination: OPERATION_MAP[action][:original] }
    end

    if OPERATION_MAP[action][:dup]
      operations << { source: item['from']['full_path'], action: 'dup', destination: OPERATION_MAP[action][:dup] }
    end

    operations
  end

  def process_operations(operations)
    operations.map do |operation|
      handle_file_deletion(operation[:source], operation[:action], operation[:destination])
    end
  end

  # source example: /vt/new/2019/2019-01-01/IMG_1234.JPG
  # destination_type example: 'removed'
  # destination_path example: /vt/data/removed/2019/2019-01-01/IMG_1234.JPG
  def get_destination_path(source, action)
    return nil unless OPERATION_MAP.keys.include?(action)

    relative_path = source.gsub(%r{^#{@config[:new_dir_path]}/}, '').gsub(%r{^#{@config[:existing_dir_path]}/}, '')
    File.join(@config[:data_dir_path], action, relative_path)
  end

  def handle_file_deletion(path, action)
    destination_path = get_destination_path(path, action)
    return "Invalid destination (#{action}) for #{path}" unless destination_path

    destination_folder = File.dirname(destination_path)
    FileUtils.mkdir_p(destination_folder) unless Dir.exist?(destination_folder)
    return "File does not exist: #{path}, destination:#{destination_path}<br>" unless File.exist?(path)

    begin
      FileUtils.mv(path, destination_path)
      "Moved (#{action}): #{path} to #{destination_path}<br>"
    rescue StandardError => e
      "Error moving (#{action}): #{path} to #{destination_path}: #{e}<br>"
    end
  end

  def find_item_by_to(data, to)
    data.each_value do |value|
      value.each do |item|
        return item if item['to'] == to
      end
    end
    nil
  end
end
