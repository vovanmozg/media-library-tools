require './cache_meta.rb'
require './spec/spec_helper'
require './comparator'

describe Comparator do
  # всего один файл в папке new, папка existing пустая
  # > ничего не делать
  it 'do nothing if only one file' do
    dir = './spec/fixtures/comparator/only_new/one_file'
    FileUtils.cp(File.join(dir, 'files_existing.json'), "#{@root}/data/files_existing.json")
    FileUtils.cp(File.join(dir, 'files_new.json'), "#{@root}/data/files_new.json")

    comparator = described_class.new(
      settings: {
        existing_dir: "#{@root}/existing",
        new_dir: "#{@root}/new",
        dups_dir: "#{@root}/dups",
        data_dir: "#{@root}/data",
      }
    )
    comparator.call
    expect(jf('/data/actions.json', @root)).to eq(jf(File.join(dir, 'actions.json')))
  end

  # файл в папке new
  # у файла не удалось получить ширину или высоту
  # > переместить файл в папку с проблемными файлами bad
  it 'moves file from new to bad if width or height is not available' do
    dir = './spec/fixtures/comparator/only_new/bad_width_height'
    FileUtils.cp(File.join(dir, 'files_existing.json'), "#{@root}/data/files_existing.json")
    FileUtils.cp(File.join(dir, 'files_new.json'), "#{@root}/data/files_new.json")

    comparator = described_class.new(
      settings: {
        existing_dir: "#{@root}/existing",
        new_dir: "#{@root}/new",
        dups_dir: "#{@root}/dups",
        data_dir: "#{@root}/data",
      }
    )
    comparator.call
    expect(jf('/data/actions.json', @root)).to eq(jf(File.join(dir, 'actions.json')))
  end

  context 'only full dups' do
    let(:cache_dir) { './spec/fixtures/comparator/full_dups'}

    # файл в папке new
    # у файла не удалось получить ширину или высоту
    # > переместить файл в папку с проблемными файлами bad
    # existing   original.jpg
    # new        exactly.jpg
    #   one      bigger.jpg
    #   two      2.png
    #     three  3.jpg

    it 'moves only full dups from new to dups' do
      FileUtils.cp('./spec/fixtures/comparator/full_dups/files_existing.json', "#{@root}/data/files_existing.json")
      FileUtils.cp('./spec/fixtures/comparator/full_dups/files_new.json', "#{@root}/data/files_new.json")

      comparator = described_class.new(
        settings: {
          existing_dir: "#{@root}/existing",
          new_dir: "#{@root}/new",
          dups_dir: "#{@root}/dups",
          data_dir: "#{@root}/data",
          existing_meta_file: 'files_existing.json',
          new_meta_file: 'files_new.json',
        }
      )
      comparator.call
      expect(jf('/data/actions.json', @root)).to eq(jf('./spec/fixtures/comparator/full_dups/actions.json'))
    end

    # написать тест, который учитывает, что фотка повернулась (поменялись
    # местами ширина и высота). При этом файлы считаются полными дубликатами -
    # ведь они имеют одинаковый размер и частичный crc32 - хотя, возможно в этом
    # случае нужно посчитать полный crc32
  end
end

