# frozen_string_literal: true

class BatchMove
  OPERATION_MAP = {
    'orig-remove-dup-skip' => { original: 'removed' },
    'orig-skip-dup-remove' => { dup: 'removed' },
    'orig-remove-dup-remove' => { original: 'removed', dup: 'removed' },
    'orig-archive-dup-remove' => { original: 'archive', dup: 'removed' },
    'orig-nofoto-dup-remove' => { original: 'new-nofoto', dup: 'removed' },
    'orig-other-dup-remove' => { original: 'new-other', dup: 'removed' },
    'orig-alien-dup-remove' => { original: 'new-alien', dup: 'removed' },
    'orig-skip-dup-skip' => {}
  }.freeze

  def call(moving_actions, all_actions, config)
    @config = config

    operations = []

    moving_actions.each do |to, action|
      item = find_item_by_to(all_actions, to)
      operations += prepare_operations(action, item)
    end

    process_operations(operations)
  end

  private

  def operation_types
    OPERATION_MAP.values.map(&:values).flatten.uniq
  end

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
  def get_destination_path(source, destination_type)
    return nil unless operation_types.include?(destination_type)

    relative_path = source.gsub(%r{^#{@config[:new_dir_path]}/}, '').gsub(%r{^#{@config[:existing_dir_path]}/}, '')
    File.join(@config[:data_dir_path], destination_type, relative_path)
  end

  def handle_file_deletion(path, type, destination_type)
    destination_path = get_destination_path(path, destination_type)
    return "Invalid destination: #{destination_type}" unless destination_path

    destination_folder = File.dirname(destination_path)
    FileUtils.mkdir_p(destination_folder) unless Dir.exist?(destination_folder)
    return "File does not exist: #{path}, destination:#{destination_path}<br>" unless File.exist?(path)

    begin
      FileUtils.mv(path, destination_path)
      "Moved #{type}: #{path} to #{destination_path}<br>"
    rescue StandardError => e
      "Error moving #{type}: #{path} to #{destination_path}: #{e}<br>"
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
