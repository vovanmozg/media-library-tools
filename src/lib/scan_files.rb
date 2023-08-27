def scan_files(dir_name, log)
  exts = %w(3gp 3gpp ai avi bmp bup cds dcm dng eps gif h264 jpeg jpg m4a m4v mov mp4 mpg mpo mts ogv png ptl scn svg tif vob webp wlmp wma wmf wmv)
  exts += exts.map(&:upcase)
  allow = exts.product([1]).to_h

  pattern = File.join(dir_name, "**/**")
  files = Dir.glob(pattern).select do |x|
    ext = File.extname(x)[1..-1]
    !File.directory?(x) && allow[ext]
  end

  log.info("Found #{files.size} files in #{dir_name}")

  files.each do |file_name|
    log.debug("Processing #{file_name}")
    yield file_name
  end
end
