require 'awesome_print'
require 'filemagic'
require 'pry-byebug'
require 'rspec'
require 'tmpdir'

RSpec.configure do |config|
  config.around do |ex|
    Dir.mktmpdir do |dir|
      @root = dir
      FileUtils.mkdir_p(
        [
          "#{@root}/existing",
          "#{@root}/new",
          "#{@root}/dups",
          "#{@root}/new_broken",
          "#{@root}/cache"
        ]
      )
      ex.run
    end
  end
end


def image(props = {})
  default = {
    type: 'image',
    phash: 1_000_000,
    width: 250,
    height: 250,
    partial_md5: '63f3c713a01010bbcafdfafa3d688566',
    size: 8359,
    name: '1.jpg',
    mtime: 1_600_000_000,
  }
  default[:id] = "#{default[:partial_md5]} #{default[:size]} #{default[:name]}"
  default.merge(props)
end

def video(props = {})
  default = {
    type: 'video',
    phash: 1_000_000,
    width: 250,
    height: 250,
    partial_md5: '63f3c713a01010bbcafdfafa3d688566',
    size: 8359,
    video_length: 4.44,
    name: '1.mp4',
    mtime: 1_600_000_000,
  }
  default[:id] = "#{default[:partial_md5]} #{default[:size]} #{default[:name]}"
  default.merge(props)
end
