require 'find'

def scan_files(dir_name, log)
  exts = %w(3gp 3gpp ai avi bmp bup cds dcm dng eps gif h264 jpeg jpg m4a m4v mov mp4 mpg mpo mts ogv png ptl scn svg tif vob webp wlmp wma wmf wmv)
  exts += exts.map(&:upcase)
  allow = exts.product([1]).to_h

  log.info("Start search files #{dir_name}")

  files = []
  Find.find(dir_name) do |path|
    if File.file?(path)
      ext = File.extname(path)[1..-1]
      files << path if allow[ext]
    end
  end

  log.info("Found #{files.size} files in #{dir_name}")

  files.each do |file_name|
    log.debug("Processing #{file_name}")
    yield file_name
  end
end
