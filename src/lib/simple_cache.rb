# frozen_string_literal: true

require 'singleton'

class SimpleCache
  include Singleton

  def initialize
    @data = {}
  end

  def read(key)
    @data[key]
  end

  def write(key, data)
    @data[key] = data
  end
end
