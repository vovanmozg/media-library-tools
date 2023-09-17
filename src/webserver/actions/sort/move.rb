require './config/constants'
require './lib/sort_batch_move'

class Sort; end
class Sort::Move
  def call(params, data_dir)
    results = SortBatchMove.new.call(params, CONFIG)
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
