# frozen_string_literal: true

class ProcessFullDups
  def initialize(new_dir, existing_dir, dups_dir, log)
    @new_dir = new_dir
    @existing_dir = existing_dir
    @dups_dir = dups_dir
    @log = log
  end

  def call(new_data, existing_data)
    existing_by_md5 = group_by_md5(existing_data)
    full_dups = compare(new_data, existing_by_md5)
    actions = generate_actions(full_dups, existing_by_md5)
    [
      {full_dups: actions},
      full_dups.keys
    ]
  end

  def generate_actions(full_dups, existing_by_md5)
    actions = []
    # processed_new_files = []

    full_dups.each do |relative_path, file_info|
      relative_path = relative_path.to_s
      original_file = existing_by_md5[file_info[:md5]].keys.first
      actions << {
        type: 'move',
        from: file_info.merge(
          relative_path:
        ),
        to: {
          root: @dups_dir,
          relative_path: File.join('full_dups', relative_path)
        },
        original: existing_by_md5[file_info[:md5]][original_file].merge(
          relative_path: original_file.to_s
        )
      }

      # processed_new_files << File.join(@new_dir, File.basename(file_name))
    end

    actions
  end

  private

  # Groups existing file data by its MD5 hash.
  # Raises an error if any file's type is 'error'.
  #
  # @param existing_data [Hash] The existing data.
  # Each key is a string representing the file path.
  # Each value is a hash with information about the file. It should at least include :type and :md5 keys.
  #
  # @example
  #   existing_data = {
  #     '/existing/file1.jpg' => {type: 'image', md5: 'abcd1234', size: 12345},
  #     '/existing/file2.jpg' => {type: 'image', md5: 'efgh5678', size: 67890}
  #   }
  #   group_by_md5(existing_data)
  #   # returns:
  #   # {
  #   #   'abcd1234' => {'/existing/file1.jpg' => {type: 'image', md5: 'abcd1234', size: 12345}},
  #   #   'efgh5678' => {'/existing/file2.jpg' => {type: 'image', md5: 'efgh5678', size: 67890}}
  #   # }
  #
  # @raise [RuntimeError] If any file's type is 'error'.
  #
  # @return [Hash] A new hash, where each key is an MD5 hash and each value is a hash mapping file paths to their data.
  def group_by_md5(existing_data)
    existing_by_md5 = Hash.new { |h, k| h[k] = {} }
    existing_data.each do |existing_file, existing_file_data|

      next if existing_file_data[:type] == 'error'

      existing_by_md5[existing_file_data[:md5]][existing_file] = existing_file_data
    end

    existing_by_md5
  end

  # Compares new data with existing data grouped by MD5 to find duplicates.
  #
  # @param new_data [Hash] The new data to be compared.
  # Each key is a string representing the file path.
  # Each value is a hash with information about the file. It should at least include :md5 key.
  #
  # @param existing_by_md5 [Hash] The existing data, grouped by MD5.
  # Each key is an MD5 hash, and each value is a hash mapping file paths to their data.
  #
  # @example
  #   new_data = {
  #     '/new/file3.jpg' => {md5: 'abcd1234', size: 12345},
  #     '/new/file4.jpg' => {md5: 'ijkl9012', size: 34567}
  #   }
  #   existing_by_md5 = {
  #     'abcd1234' => {'/existing/file1.jpg' => {md5: 'abcd1234', size: 12345}},
  #     'efgh5678' => {'/existing/file2.jpg' => {md5: 'efgh5678', size: 67890}}
  #   }
  #   compare(new_data, existing_by_md5)
  #   # returns:
  #   # {
  #   #   '/new/file3.jpg' => {md5: 'abcd1234', size: 12345}
  #   # }
  #
  # @return [Hash] A new hash representing the files in `new_data` that have the same MD5 as any file in `existing_by_md5`.
  # Each key is a string representing the file path and each value is a hash with the file's information.
  def compare(new_data, existing_by_md5)
    full_dups = {}
    new_data.each do |new_file, new_file_info|
      full_dups[new_file] = new_file_info if existing_by_md5.key?(new_file_info[:md5])
    end
    full_dups
  end
end
