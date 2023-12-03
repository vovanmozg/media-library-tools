# frozen_string_literal: true

require 'find'
require 'filemagic'
require './lib/media'

class ManualDups; end
class ManualDups::Realtime
  FM = FileMagic.new

  # @param pattern [String] regexp для выбора файлов по пути
  def call(per: 50, page: 1, pattern: nil, threshold: 12)
    searcher = Images::Dups.new
    @media = Media.new('/vt/data', LOG)
    @threshold = threshold
    infos = []

    scan_files('/vt/new', per, pattern, LOG) do |file_name|
      info = @media.read_file!(file_name, FM)
      info[:file_name] = file_name
      info[:duplicates] = searcher.find(info, threshold).map do |dup|
        dup[:file_name] = @media.read_file!(dup[:file], FM)
        dup
      end

      infos << info
    end

    infos
  end



  def call(cache_dir)
    data = JSON.parse(File.read(File.join(cache_dir, 'actions.json')))

    # Merge all items from all areas to one array
    all_items = []
    data['skipped'] = []
    data.each do |action_type, subitems|
      subitems.each do |subitem|
        subitem['action_type'] = action_type
        all_items << subitem
      end
    end

    all_items.sort_by! { |item| item['original']['phash'] }

    # max_entries = [data[selected_area].length, PAGE_SIZE].min
    # max_entries = [all_items.length, PAGE_SIZE].min

    selected, skipped_count = select(all_items)
    [selected, data.count, skipped_count]
  end

  def realtime(cache_dir)

  end

  private

  def transform_docker_path_to_url(path)
    IMG_URL_PREFIX + path
  end

  def item_params(item)
    o = item["original"]
    d = item["from"].merge(item["dup"])

    original_path = o["real_path"]
    dup_path = d["full_path"]

    # linux_original_path = original_path.gsub('\\', '/').gsub(WIN_DIR, REAL_PATH_PREFIX)
    # linux_dup_path = dup_path.gsub('\\', '/').gsub(WIN_DIR, REAL_PATH_PREFIX)

    o_exists = File.exist?(o["full_path"])
    d_exists = File.exist?(d["full_path"])

    if !o_exists || !d_exists
      return
    end


    original_size = File.size(o["full_path"])
    dup_size = File.size(d["full_path"])

    display_original_path = o['full_path'].gsub("/vt/new/", '').gsub("/vt/existing/", '')
    display_dup_path = d['full_path'].gsub("/vt/new/", '')

    original_img_height = DEFAULT_THUMB_WIDTH * o["height"] / o["width"]
    original_img_height = DEFAULT_THUMB_WIDTH / 2 unless original_img_height

    dup_img_height = DEFAULT_THUMB_WIDTH * d["height"] / d["width"]
    dup_img_height = original_img_height unless dup_img_height > 0

    img_original_class = ""
    img_dup_class = ""

    if o["width"] > d["width"]
      img_dup_class = "smaller"
      img_original_class = ""
      dup_img_height *= SMALLER_THUMB_RATIO
    elsif o["width"] < d["width"]
      img_original_class = "smaller"
      img_dup_class = ""
      original_img_height *= SMALLER_THUMB_RATIO
    end

    # original_image_details = `identify #{linux_original_path}`
    # dup_image_details = `identify #{linux_dup_path}`


    # is_same_resolution = o["width"] == d["width"] && o["height"] == d["height"]
    # is_original_heavier_same_resolution = is_same_resolution && o["size"] > d["size"]
    # is_dup_heavier_same_resolution = is_same_resolution && d["size"] > o["size"]

    # is_dup_better = is_original_heavier_same_resolution


    ({
      dup_img_url: transform_docker_path_to_url(d["full_path"]),
      original_img_url: transform_docker_path_to_url(o["full_path"]),
      original_img_height: original_img_height,
      original_width: o["width"],
      original_height: o["height"],
      original_phash: o["phash"],
      dup_phash: d["phash"],
      dup_width: d["width"],
      dup_height: d["height"],
      original_path: original_path,
      original_size: original_size,
      default_action: get_default_action(o, d),
      dup_path: dup_path,
      dup_img_height: dup_img_height,
      img_original_class: img_original_class,
      img_dup_class: img_dup_class,
      display_original_path: display_original_path,
      display_dup_path: display_dup_path,
      dup_size: dup_size,
      to: item["to"],
      action_type: item["action_type"]
    })
  end

  def select(items)
    result = []
    skipped_count = 0

    items.each do |item_info|
      return result if result.size >= PAGE_SIZE

      item = item_params(item_info)
      unless item
        skipped_count += 1
        next
      end

      result << item
    end

    [result, skipped_count]
  end

  def get_default_action(o, d)
    if o['full_path'].include?('nofoto') || d['full_path'].include?('nofoto')
      return 'orig-nofoto-dup-remove'
    end

    if o['full_path'].include?('alien') || d['full_path'].include?('alien')
      return 'orig-alien-dup-remove'
    end

    if o['full_path'].include?('fotoother') || d['full_path'].include?('fotoother') || o['full_path'].include?('foto-other') || d['full_path'].include?('foto-other')
      return 'orig-other-dup-remove'
    end

    is_same_resolution = o["width"] == d["width"] && o["height"] == d["height"]
    is_original_heavier_same_resolution = is_same_resolution && o["size"] > d["size"]
    # is_dup_heavier_same_resolution = is_same_resolution && d["size"] > o["size"]

    is_dup_better = is_original_heavier_same_resolution

    is_dup_better ? 'orig-remove-dup-skip' : 'orig-skip-dup-remove'
  end
end
