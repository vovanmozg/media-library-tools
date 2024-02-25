# frozen_string_literal: true

require 'json'
require './lib/read_phashes'

class Phashes; end

class Phashes
  class Index
    def initialize(data_dir)
      @data_dir = data_dir
    end

    def call
      ReadPhashes.new(@data_dir).from_cache
    end
  end
end
