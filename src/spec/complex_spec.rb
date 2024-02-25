require './cache_meta.rb'

require './spec/spec_helper'
require './comparator'
require './meta_reader'
require './operations_maker'
require './lib/mover'

describe 'Complex' do
  let(:cache_dir) { "#{@root}/data" }

  context 'only full dups' do
    it 'tests all steps' do
      # Prepare media files
      # Эти копирования файлов только запутывают. Тест манипулирует данными из
      # кеша, а эти файлы нужны только для того чтобы выполнить glob
      FileUtils.mkdir_p(cache_dir)
      FileUtils.mkdir_p("#{@root}/existing")
      FileUtils.mkdir_p("#{@root}/new/one")
      FileUtils.mkdir_p("#{@root}/new/two/three")
      FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/existing/original.jpg")
      FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/exactly.jpg")
      FileUtils.cp('./spec/fixtures/media/2 smaller.jpg', "#{@root}/new/one/smaller.jpg")
      FileUtils.cp('./spec/fixtures/media/9.png', "#{@root}/new/two/2.jpg")
      FileUtils.cp('./spec/fixtures/media/10.jpg', "#{@root}/new/two/three/3.png")
      FileUtils.touch("#{@root}/existing/original.jpg", mtime: 1_600_000_000)
      FileUtils.touch("#{@root}/new/exactly.jpg", mtime: 1_600_000_000)
      FileUtils.touch("#{@root}/new/one/smaller.jpg", mtime: 1_600_000_000)
      FileUtils.touch("#{@root}/new/two/2.jpg", mtime: 1_600_000_000)
      FileUtils.touch("#{@root}/new/two/three/3.png", mtime: 1_600_000_000)

      # Read meta to json-file
      MetaReader.new(
        media_dir: "#{@root}/existing",
        data_dir: "#{@root}/data",
        media_meta_path: 'files_existing.json'
      ).call

      MetaReader.new(
        media_dir: "#{@root}/new",
        data_dir: "#{@root}/data",
        media_meta_path: 'files_new.json'
      ).call

      expect(jf('./spec/fixtures/complex/files_existing.json')).to eq(jf('/data/files_existing.json', @root))
      expect(jf('./spec/fixtures/complex/files_new.json')).to eq(jf('/data/files_new.json', @root))

      # Compare meta
      comparator = Comparator.new(
        settings: {
          existing_dir: "#{@root}/existing",
          new_dir: "#{@root}/new",
          dups_dir: "#{@root}/dups",
          data_dir: cache_dir
        }
      )
      comparator.call
      expect(jf('./spec/fixtures/complex/actions.json')).to eq(jf('/data/actions.json', @root))

      # Prepare operations in json format. This step contains real paths
      #  replacement
      OperationsMaker.new(
        settings: {
          data_dir: cache_dir,
          existing_dir: "#{@root}/existing",
          real_existing_dir: "REAL/existing",
          new_dir: "#{@root}/new",
          real_new_dir: "REAL/new",
          dups_dir: "#{@root}/dups",
          real_dups_dir: "REAL/dups"
        }
      ).call
      expect(jf('/data/operations.json', @root)).to eq(jf('./spec/fixtures/complex/operations.json'))


      # Generate bahs-file to move files
      mover = Mover.new(settings: {
        data_dir: cache_dir,
        operations_file: 'operations.json',
        driver_type: :linux
      })

      actual = mover.call.join("\n")
      expected = File.read('./spec/fixtures/complex/commands.sh.txt')

      expect(actual).to eq(expected)
    end
  end
end

