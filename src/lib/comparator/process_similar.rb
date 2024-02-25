# frozen_string_literal: true

class ProcessSimilar
  def initialize(new_dir, existing_dir, dups_dir, log)
    @new_dir = new_dir
    @existing_dir = existing_dir
    @dups_dir = dups_dir
    @log = log
  end

  def call(new_data, existing_data)
    existing_by_phash = group_by_phash(existing_data)
    similar = compare_exact(new_data, existing_by_phash)
    actions = generate_actions(similar, existing_by_phash)
    [
      { similar: actions },
      similar.keys
    ]
  end

  def generate_actions(similar, existing_by_phash)
    actions = []
    # processed_new_files = []

    similar.each do |relative_path, file_info|
      original_file = existing_by_phash[file_info[:phash]].keys.first

      actions << {
        type: 'move',
        from: file_info.merge(relative_path: relative_path.to_s),
        to: { root: @dups_dir, relative_path: File.join('similar', relative_path.to_s) },
        original: existing_by_phash[file_info[:phash]][original_file].merge(relative_path: original_file.to_s)
      }

      # processed_new_files << File.join(@new_dir, File.basename(file_name))
    end

    actions
  end

  private

  # Groups existing file data by its phash.
  # Raises an error if any file's type is 'error'.
  #
  # @param existing_data [Hash] The existing data.
  # Each key is a string representing the file path.
  # Each value is a hash with information about the file. It should at least include :type and :phash keys.
  #
  # @example
  #   existing_data = {
  #     '/existing/file1.jpg' => {type: 'image', phash: 'abcd1234', size: 12345},
  #     '/existing/file2.jpg' => {type: 'image', phash: 'efgh5678', size: 67890}
  #   }
  #   group_by_phash(existing_data)
  #   # returns:
  #   # {
  #   #   'abcd1234' => {'/existing/file1.jpg' => {type: 'image', phash: 'abcd1234', size: 12345}},
  #   #   'efgh5678' => {'/existing/file2.jpg' => {type: 'image', phash: 'efgh5678', size: 67890}}
  #   # }
  #
  # @raise [RuntimeError] If any file's type is 'error'.
  #
  # @return [Hash] A new hash, where each key is an phash and each value is a hash mapping file paths to their data.
  def group_by_phash(existing_data)
    existing_by_phash = Hash.new { |h, k| h[k] = {} }

    existing_data.each do |existing_file, existing_file_data|
      next if existing_file_data[:type] == 'error'

      existing_by_phash[existing_file_data[:phash]][existing_file] = existing_file_data
    end

    existing_by_phash
  end

  # Compares new data with existing data grouped by phash to find duplicates.
  #
  # @param new_data [Hash] The new data to be compared.
  # Each key is a string representing the file path.
  # Each value is a hash with information about the file. It should at least include :phash key.
  #
  # @param existing_by_phash [Hash] The existing data, grouped by phash.
  # Each key is an phash, and each value is a hash mapping file paths to their data.
  #
  # @example
  #   new_data = {
  #     '/new/file3.jpg' => {phash: 'abcd1234', size: 12345},
  #     '/new/file4.jpg' => {phash: 'ijkl9012', size: 34567}
  #   }
  #   existing_by_phash = {
  #     'abcd1234' => {'/existing/file1.jpg' => {phash: 'abcd1234', size: 12345}},
  #     'efgh5678' => {'/existing/file2.jpg' => {phash: 'efgh5678', size: 67890}}
  #   }
  #   compare(new_data, existing_by_phash)
  #   # returns:
  #   # {
  #   #   '/new/file3.jpg' => {phash: 'abcd1234', size: 12345}
  #   # }
  #
  # @return [Hash] A new hash representing the files in `new_data` that have the same phash as any file in `existing_by_phash`.
  # Each key is a string representing the file path and each value is a hash with the file's information.
  def compare_exact(new_data, existing_by_phash)
    similar = {}
    new_data.each do |new_file, new_file_info|
      similar[new_file] = new_file_info if existing_by_phash.key?(new_file_info[:phash])
    end
    similar
  end
end
