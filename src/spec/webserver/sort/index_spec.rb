# frozen_string_literal: true

require './spec/spec_helper'
require './webserver/actions/sort/index'
require './lib/log'

describe '1' do
  xit 'ku' do
    i = 0

    Sort::Index.new.scan_files('/vt/new', 50, Logger.new($stdout)) do |file_name|
      p file_name
      i += 1
    end

    puts i
  end
end
