require 'logger'
require './lib/utils'

LOG = Logger.new(STDOUT)
LOG.level = (ENV['LOG_LEVEL'] && Object.const_get(ENV['LOG_LEVEL'])) || Logger::DEBUG


# счетчики для записи в файл. Скрипт стандартно ничего не выводит в stdout,
# поэтому для отслеживания прогресса можно смотреть в файл.
# watch -n 1 cat progress.json

class Counters
  @@instances_created = 0
  @@counters = {}

  def initialize(type, root_cache_dir)
    @type = type
    @root_cache_dir = root_cache_dir

    init_counters
  end

  def increase(prefix)
    key = "#{@type}_#{prefix}".to_sym
    @@counters[key] = @@counters[key] ? @@counters[key] + 1 : 0
    save_progress(@@counters)
  end

  def save_progress(value = {})
    return
    progress_file = File.join(@root_cache_dir, 'progress.json')
    progress = File.exist?(progress_file) ? JSON.parse(File.read(progress_file), symbolize_names: true) : {}

    progress.merge!(value)
    File.write(progress_file, JSON.pretty_generate(progress))
  end

  def init_counters
    @@instances_created += 1
    if @@instances_created == 1
      save_progress({})
    end
  end
end
