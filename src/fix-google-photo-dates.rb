# You can download all photos and vides from google photo using Google Takeout.
# The problem is that the dates of the photos and videos are not correct.
# This script fixes the dates of the photos and videos using metadata,
# contained in json files, which are also downloaded from Google Takeout.

require 'json'
require 'exif'
require 'streamio-ffmpeg'

def main
  media_dir = '/app/media'

  # read list of all files with subdirectories from ROOT_DIR except json files
  all_files = Dir.glob(File.join(media_dir, '**/**'))
  media_files = all_files.reject { |x| File.directory?(x) || x.end_with?('.json', '.txt', '.ini') }
  media_files.each do |file_name|
    timestamp = get_time(file_name)

    unless timestamp
      p "WARN: It is impossible to get timestamp for #{file_name}"
      next
    end

    # convert timestamp to YYYYMMDDhhmm.ss
    date_time = Time.at(timestamp).strftime('%Y%m%d%H%M.%S')

    # set date to file
    system("touch -t #{date_time} '#{file_name}'")
  end
end

def get_time(file_name)
  timestamp = get_time_from_json(file_name)
  return timestamp.to_i if timestamp

  timestamp = get_time_from_media_info(file_name)
  return timestamp.to_i if timestamp

  timestamp = get_time_from_file_name(file_name)
  return timestamp.to_i if timestamp

  nil
end

def get_time_from_json(file_name)
  json_file_name = file_name + '.json'

  return nil unless File.exist?(json_file_name)

  json = JSON.parse(File.read(json_file_name))

  timestamp = json['photoTakenTime']['timestamp']
  return timestamp if timestamp?(timestamp)

  json['creationTime']['timestamp']
end

def get_time_from_media_info(file_name)
  timestamp = get_creation_date_from_image(file_name)
  return timestamp if timestamp

  get_creation_date_from_video(file_name)
end

def get_creation_date_from_image(image_path)
  exif = Exif::Data.new(image_path)
  p exif
  exif.date_time_original
rescue Exif::NotReadable
  p "WARN: Exif::NotReadable #{image_path}"
  nil
end

def get_time_from_file_name(file_name)
  # IMG_20181204_154651.jpg
  match = file_name.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})/)
  timestamp = to_timestamp(match)
  return timestamp if timestamp?(timestamp)

  # Screenshot_2020-02-15-23-26-15-252_com.android..jpg
  match = file_name.match(/(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})/)
  timestamp = to_timestamp(match)
  return timestamp if timestamp?(timestamp)

  # 2018-02-25 15-39-09_14-01-47.jpg
  match = file_name.match(/(\d{4})-(\d{2})-(\d{2}) (\d{2})-(\d{2})-(\d{2})/)
  timestamp = to_timestamp(match)
  return timestamp if timestamp?(timestamp)

  # FaceApp_1592587915863.jpg (where numbers from 315532800000 - 4102444800000)
  # regex: FaceApp_(\d{13}).jpg
  match = file_name.match(/\D(\d{12,13})\D/)
  if match
    ts = match[1].to_i / 1000
    return ts if timestamp?(ts)
  end

  # IMG-20200309-WA0000.jpg
  match = file_name.match(/(\d{4})(\d{2})(\d{2})/)
  timestamp = to_timestamp(match)
  return timestamp if timestamp?(timestamp)

  # (2009-06-27) IMG_1198(1).JPG
  match = file_name.match(/(\d{4})-(\d{2})-(\d{2})/)
  timestamp = to_timestamp(match)
  return timestamp if timestamp?(timestamp)

  nil
end

def to_timestamp(match)
  return nil unless match

  year = match[1]
  month = match[2]
  day = match[3]
  hour = match[4]
  minute = match[5]
  second = match[6]

  Time.new(year, month, day, hour, minute, second).to_i
rescue ArgumentError => e
  p "ERROR: #{e.message} for #{match}]}"
end

def get_creation_date_from_video(video_path)
  movie = FFMPEG::Movie.new(video_path)
  movie.creation_time
end

# Is timestamp valid and large enough (not less 1980 year)
# We assume that if the timestamp of the photos indicates a year before 1980,
# then something is wrong with the timestamp
def timestamp?(ts)
  ts1980 = 315532800
  ts2100 = 4102444800
  ts = ts.to_s
  /^\d+$/.match?(ts) && ts.to_i > ts1980 && ts.to_i < ts2100
end

main
