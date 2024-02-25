# frozen_string_literal: true

require 'optparse'
require './lib/utils'
require './comparator'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: compare.rb [options]'

  opts.on('-m', '--actions_path=[ACTIONS_PATH]', '') do |v|
    options[:actions_path] = v
  end

  # is it needed to process files inside new dir, which are full dups
  opts.on('-m', '--inside_new_full_dups=[INSIDE_NEW_FULL_DUPS]', '') do |v|
    options[:inside_new_full_dups] = to_boolean(v)
  end

  # is it needed to process files inside new dir, which are full dups
  opts.on('-m', '--inside_new_similar=[INSIDE_NEW_SIMILAR]', '') do |v|
    options[:inside_new_similar] = to_boolean(v)
  end

  # is it needed to process files inside new dir, which are full dups
  opts.on('-m', '--inside_new_doubtful=[INSIDE_NEW_DOUBTFUL]', '') do |v|
    options[:inside_new_doubtful] = to_boolean(v)
  end

  # is it needed to process files inside new dir, which are full dups
  opts.on('-m', '--full_dups=[FULL_DUPS]', '') do |v|
    options[:full_dups] = to_boolean(v)
  end

  # is it needed to process files inside new dir, which are full dups
  opts.on('-m', '--similar=[SIMILAR]', '') do |v|
    options[:similar] = to_boolean(v)
  end

  opts.on('-m', '--show_skipped=[SHOW_SKIPPED]', '') do |v|
    options[:show_skipped] = to_boolean(v)
  end

  # json file with meta for existing files
  opts.on('-m', '--existing_meta_file=[EXISTING_META_FILE]', '') do |v|
    options[:existing_meta_file] = v
  end

  # json file with meta for new files
  opts.on('-m', '--new_meta_file=[NEW_META_FILE]', '') do |v|
    options[:new_meta_file] = v
  end
end

parser.parse!

Comparator.new(settings: options).call
