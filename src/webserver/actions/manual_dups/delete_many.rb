# frozen_string_literal: true

require './lib/batch_move'
require './config/constants'

class ManualDups; end
class ManualDups::DeleteMany
  def call(params, cache_dir)
    data = JSON.parse(File.read(File.join(cache_dir, 'actions.json')))
    results = BatchMove.new.call(params, data, CONFIG)
    save_log(results)
    results
  end

  def save_log(results)
    log_file_name = File.join(CONFIG[:data_dir_path], 'move.log')
    File.touch(log_file_name) unless File.exist?(log_file_name)
    open(log_file_name, 'a') do |f|
      f.puts results.map {|line| "#{Time.now.strftime("%Y-%m-%d %H-%M-%S")} #{line}" }.join("\n")
    end
  end
end
