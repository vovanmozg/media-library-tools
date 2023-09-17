require 'sinatra/base'
require 'json'
require 'fileutils' # для работы с файлами
require 'rmagick'

require './webserver/actions/manual_dups/index'
require './webserver/actions/manual_dups/delete_many'
require './webserver/actions/images/show'
require './webserver/actions/sort/index'
require './webserver/actions/sort/move'

# Глобальные переменные
# WIN_DIR = 'F:/media'
# REAL_PATH_PREFIX = '/mnt/media'
# DEFAULT_REAL_NEW_PATH_PREFIX = '/dups-new'
# DEFAULT_REAL_EXISTING_PATH_PREFIX = '/images-new'
IMG_URL_PREFIX = '/image?path='
PAGE_SIZE = 50
DEFAULT_THUMB_WIDTH = 200
SMALLER_THUMB_RATIO = 0.8
DOCKER_PATH_PREFIX = '/vt'
DOCKER_PATH_NEW_PREFIX = '/vt/new'
DOCKER_PATH_EXISTING_PATH_PREFIX = '/vt/existing'
DATA_DIR = '/vt/data'

class MyApp < Sinatra::Base
  get '/' do
    erb :index
  end

  def read_move_log
    file_name = File.join(DATA_DIR, 'move.log')
    return '' unless File.exist?(file_name)

    File.read(file_name).split("\n").last(20).reverse.join("\n")
  end

  get '/dups' do
    @selected_items, @all_items_count, @skipped_count = ManualDups::Index.new.call(DATA_DIR)
    @log = read_move_log
    erb :dups
  end

  # Обработка POST-запроса
  post '/dups' do
    ManualDups::DeleteMany.new.call(params['imageAction'], DATA_DIR)
    redirect '/dups'
  end

  get '/sort' do
    items_count = params['items_count'].to_i > 0 ? params['items_count'].to_i : 50
    puts '________'
    puts items_count
    @media_items = Sort::Index.new.call(items_count)
    @log = read_move_log
    erb :'sort/index'
  end

  post '/sort' do
    Sort::Move.new.call(params['imageAction'], DATA_DIR)
    redirect '/sort'
  end

  get '/image' do
    result = Images::Show.new.call(params['path'], params.has_key?('x'), DATA_DIR)
    if result[:type] == :content
      content_type 'image/jpeg'
      result[:data]
    elsif result[:type] == :stream
      send_file(result[:data], type: 'image/jpeg', disposition: 'inline')
    else
      result[:data]
    end
  end

  # Запуск приложения
  if app_file == $0
    set :bind, '0.0.0.0'
    set :port, 4567
    run!
  end

end
