require './spec/spec_helper'
require './webserver/actions/sort/index'
require './lib/log'

describe '1' do
  it 'ku' do
    i = 0

    Sort::Index.new.scan_files('/vt/new', 50, Logger.new(STDOUT)) do |file_name|
      p file_name
      i += 1
    end

    files = []

    puts i

  end
end

