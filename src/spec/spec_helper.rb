# frozen_string_literal: true

require 'awesome_print'
require 'filemagic'
require 'pry-byebug'
require 'rspec'
require 'tmpdir'
require 'json'

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

RSpec.configure do |config|
  config.around do |ex|
    Dir.mktmpdir do |dir|
      @root = dir
      FileUtils.mkdir_p(
        [
          "#{@root}/existing",
          "#{@root}/new",
          "#{@root}/media",
          "#{@root}/dups",
          "#{@root}/new_broken",
          "#{@root}/data"
        ]
      )
      ex.run
    end
  end
end
