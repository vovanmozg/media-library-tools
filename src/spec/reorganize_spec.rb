# frozen_string_literal: true
# require './spec/spec_helper'
# require './reorganize'
#
# describe Reorganizer do
#   let(:cache_dir) { "#{@root}/cache" }
#
#   # Удаление файлов кэша перед каждым тестом нужно потому что, папка phash
#   # в фикстурах нужна, а эти файлы - нет. Т.е. эти команды удаления нужны
#   # для тех случаев когда кэш - это папка из фикстур, а не временная папка
#   before do
#     FileUtils.rm(
#       [
#         "#{cache_dir}/existing_files.json",
#         "#{cache_dir}/new_files.json",
#         "#{cache_dir}/progress.json"
#       ],
#       force: true
#     )
#   end
#
#   after do
#     FileUtils.rm(
#       [
#         "#{cache_dir}/existing_files.json",
#         "#{cache_dir}/new_files.json",
#         "#{cache_dir}/progress.json"
#       ],
#       force: true
#     )
#   end
#
#   # context do
#   #   let(:cache_dir) { './spec/fixtures/reorganizer/only_new/one_file' }
#   #
#   #   # всего один файл в папке new, папка existing пустая
#   #   # > ничего не делать
#   #   it 'do nothing if only one file' do
#   #     FileUtils.mkdir_p("#{@root}/new/x")
#   #     FileUtils.cp('./spec/fixtures/media/dull.mp4', "#{@root}/new/x/1.mp4")
#   #     FileUtils.touch("#{@root}/new/x/1.mp4", mtime: 1_600_000_000)
#   #
#   #     reorganizer = described_class.new(
#   #       {
#   #         existing_dir: "#{@root}/existing",
#   #         new_dir: "#{@root}/new",
#   #         dups_dir: "#{@root}/dups",
#   #         data_dir: cache_dir
#   #       },
#   #       system: :linux
#   #     )
#   #
#   #     cmds = reorganizer.call
#   #
#   #     expected = [
#   #       '# Summary:',
#   #       '#   Identical files inside new dir: 0',
#   #       '#   Similar files inside new dir: 0',
#   #       '#   Doubtful similar files inside new dir: 0',
#   #       '#   Files in new identical to existing: 0',
#   #       '#   Files in new similar to existing: 0',
#   #       '#   Broken files: 0',
#   #       '#   total: 0',
#   #       '#'
#   #     ]
#   #
#   #     expect(cmds).to eq(expected)
#   #   end
#   # end
#   #
#   # context do
#   #   let(:cache_dir) { './spec/fixtures/reorganizer/only_new/bad_width_height'}
#   #
#   #   # файл в папке new
#   #   # у файла не удалось получить ширину или высоту
#   #   # > переместить файл в папку с проблемными файлами bad
#   #   it 'moves file from new to bad if width or height is not available' do
#   #     FileUtils.mkdir_p("#{@root}/new/x")
#   #     FileUtils.cp('./spec/fixtures/media/dull.mp4', "#{@root}/new/x/1.mp4")
#   #     FileUtils.touch("#{@root}/new/x/1.mp4", mtime: 1_600_000_000)
#   #
#   #     reorganizer = described_class.new(
#   #       {
#   #         existing_dir: "#{@root}/existing",
#   #         new_dir: "#{@root}/new",
#   #         dups_dir: "#{@root}/dups",
#   #         data_dir: cache_dir
#   #       },
#   #       system: :linux
#   #     )
#   #
#   #     cmds = reorganizer.call
#   #     expected = [
#   #       '# Summary:',
#   #       '#   Identical files inside new dir: 0',
#   #       '#   Similar files inside new dir: 0',
#   #       '#   Doubtful similar files inside new dir: 0',
#   #       '#   Files in new identical to existing: 0',
#   #       '#   Files in new similar to existing: 0',
#   #       '#   Broken files: 1',
#   #       '#   total: 1',
#   #       '#',
#   #       '################',
#   #       '# Broken files #',
#   #       '################',
#   #       "# #{@root}/new/x/1.mp4, wrong dimensions: 240x",
#   #       %Q(mkdir -p "#{@root}/dups/new_broken/x"),
#   #       %Q(mv "#{@root}/new/x/1.mp4" "#{@root}/dups/new_broken/x/1.mp4"),
#   #       ''
#   #     ]
#   #
#   #     expect(cmds).to eq(expected)
#   #   end
#   # end
#
#   context do
#     let(:cache_dir) { './spec/fixtures/reorganizer/only_new/bad_size'}
#
#     # файл в папке new
#     # у файла не удалось получить ширину или высоту
#     # > переместить файл в папку с проблемными файлами bad
#     it 'moves file from new to bad if size is not available' do
#       FileUtils.mkdir_p("#{@root}/new/x")
#       FileUtils.cp('./spec/fixtures/media/1.mp4', "#{@root}/new/x/1.mp4")
#       FileUtils.touch("#{@root}/new/x/1.mp4", mtime: 1_600_000_000)
#
#       reorganizer = described_class.new(
#         {
#           existing_dir: "#{@root}/existing",
#           new_dir: "#{@root}/new",
#           dups_dir: "#{@root}/dups",
#           data_dir: cache_dir
#         },
#         system: :linux
#       )
#
#       cmds = reorganizer.call
#       expected = [
#         '# Summary:',
#         '#   Identical files inside new dir: 0',
#         '#   Similar files inside new dir: 0',
#         '#   Doubtful similar files inside new dir: 0',
#         '#   Files in new identical to existing: 0',
#         '#   Files in new similar to existing: 0',
#         '#   Broken files: 1',
#         '#   total: 1',
#         '#',
#         '################',
#         '# Broken files #',
#         '################',
#         "# #{@root}/new/x/1.mp4, wrong length: 442877",
#         %Q(mkdir -p "#{@root}/dups/new_broken/x"),
#         %Q(mv "#{@root}/new/x/1.mp4" "#{@root}/dups/new_broken/x/1.mp4"),
#         ''
#       ]
#
#       expect(cmds).to eq(expected)
#     end
#
#     # в папке есть несколько фото попарный distance которых < 2, но если их
#     # сгруппировать, то между некоторыми парами distance > 2
#     # > ничего не делаем
#     it 'does not process files with distance 20' do
#       # Эти копирования файлов только запутывают. Тест манипулирует данными из
#       # кеша, а эти файлы нужны только для того чтобы выполнить glob
#       FileUtils.mkdir_p("#{@root}/new/x")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/1.jpg")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/2.jpg")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/3.jpg")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/4.jpg")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/5.jpg")
#       Dir.glob("#{@root}/new/x/*.jpg").each_with_index do |file_name, i|
#         File.open(file_name, 'rb+') do |file|
#           file.seek(1000, IO::SEEK_SET)
#           file.putc(i)
#         end
#       end
#       FileUtils.touch("#{@root}/new/x/1.jpg", mtime: 1_600_000_000)
#       FileUtils.touch("#{@root}/new/x/2.jpg", mtime: 1_600_000_000)
#       FileUtils.touch("#{@root}/new/x/3.jpg", mtime: 1_600_000_000)
#       FileUtils.touch("#{@root}/new/x/4.jpg", mtime: 1_600_000_000)
#       FileUtils.touch("#{@root}/new/x/5.jpg", mtime: 1_600_000_000)
#
#       reorganizer = described_class.new(
#         {
#           existing_dir: "#{@root}/existing",
#           new_dir: "#{@root}/new",
#           dups_dir: "#{@root}/dups",
#           data_dir: './spec/fixtures/reorganizer/only_new/similar_but_diff'
#         },
#         system: :linux
#       )
#
#       cmds = reorganizer.call
#       expected = [
#         '# Summary:',
#         '#   Identical files inside new dir: 0',
#         '#   Similar files inside new dir: 0',
#         '#   Doubtful similar files inside new dir: 0',
#         '#   Files in new identical to existing: 0',
#         '#   Files in new similar to existing: 0',
#         '#   Broken files: 0',
#         '#   total: 0',
#         '#'
#       ]
#       expect(cmds).to eq(expected)
#     end
#   end
#
#   context 'only full dups' do
#     let(:cache_dir) { './spec/fixtures/reorganizer/only_new/remove_full_dups'}
#
#     # файл в папке new
#     # у файла не удалось получить ширину или высоту
#     # > переместить файл в папку с проблемными файлами bad
#     # existing   original.jpg
#     # new        exactly.jpg
#     #   one      bigger.jpg
#     #   two      2.png
#     #     three  3.jpg
#
#     it 'moves only full dups from new to dups' do
#       # Эти копирования файлов только запутывают. Тест манипулирует данными из
#       # кеша, а эти файлы нужны только для того чтобы выполнить glob
#       FileUtils.mkdir_p("#{@root}/existing")
#       FileUtils.mkdir_p("#{@root}/new/one")
#       FileUtils.mkdir_p("#{@root}/new/two/three")
#       FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/existing/original.jpg")
#       FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/exactly.jpg")
#       FileUtils.cp('./spec/fixtures/media/1-copy.jpg', "#{@root}/new/one/bigger.jpg")
#       FileUtils.cp('./spec/fixtures/media/1-2.png', "#{@root}/new/two/2.jpg")
#       FileUtils.cp('./spec/fixtures/media/1-3.jpg', "#{@root}/new/two/three/3.png")
#
#       # require 'fileutils'
#       # FileUtils.cp_r "source/.", 'dst', :verbose => true
#
#       reorganizer = described_class.new(
#         {
#           existing_dir: "#{@root}/existing",
#           new_dir: "#{@root}/new",
#           dups_dir: "#{@root}/dups",
#           data_dir: cache_dir
#         },
#         settings: {
#           inside_new_full_dups: false,
#           inside_new_similar: false,
#           inside_new_doubtful: false,
#           full_dups: true,
#           similar: false
#         },
#         system: :linux
#       )
#
#       cmds = reorganizer.call
#       expected = [
#         '# Summary:',
#         '#   Identical files inside new dir: 0',
#         '#   Similar files inside new dir: 0',
#         '#   Doubtful similar files inside new dir: 0',
#         '#   Files in new identical to existing: 1',
#         '#   Files in new similar to existing: 0',
#         '#   Broken files: 0',
#         '#   total: 1',
#         '#',
#         '######################################',
#         '# Files in new identical to existing #',
#         '######################################',
#         %Q(# original: #{@root}/existing/original.jpg 250x250 (ratio 1.0), size: 8359, #{Time.at(File.mtime("#{@root}/existing/original.jpg").to_i).strftime('%Y-%m-%d %H:%M:%S')}),
#         %Q(# dup: 250x250 (ratio 1.0), size: 8359, distance: 0, #{Time.at(File.mtime("#{@root}/existing/original.jpg").to_i).strftime('%Y-%m-%d %H:%M:%S')}),
#         %Q(mkdir -p '#{@root}/dups/new_full_dups'),
#         %Q(mv '#{@root}/new/exactly.jpg' '#{@root}/dups/new_full_dups/exactly.jpg'),
#         ''
#       ]
#
#       expect(cmds).to match_array(expected)
#     end
#   end
#
#   # оба файла в папке new
#   # файлы идентичные, но имеют разную дату модификации
#   # > самый старый файл оставить на месте
#   # > остальные файлы поместить в папку с полными дубликатами new_inside_full_dups
#
#   # оба файла в папке new
#   # файлы идентичные, имеют одинаковую дату модификации, но имеют разную длину имени файла
#   # > файл с максимальной длиной оставить на месте
#   # > остальные файлы поместить в папку с полными дубликатами new_inside_full_dups
#
#
#
#   # оба файла в папке new
#   # файлы идентичные
#   # > первый попавшийся файл оставить на месте
#   # > остальные файлы поместить в папку с полными дубликатами new_inside_full_dups
#   context 'without cache' do
#     it 'should move file to new_inside_full_dups if files are identical' do
#       FileUtils.mkdir_p(["#{@root}/existing", "#{@root}/new", "#{@root}/dups", "#{@root}/cache"])
#       FileUtils.mkdir_p("#{@root}/new/x")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/1.jpg")
#       FileUtils.cp('./spec/fixtures/media/dull.jpg', "#{@root}/new/x/2.jpg")
#       FileUtils.touch("#{@root}/new/x/1.jpg", mtime: 1_600_000_000)
#       FileUtils.touch("#{@root}/new/x/2.jpg", mtime: 1_600_000_000)
#
#       # reorganizer = described_class.new("#{@root}/existing", "#{@root}/new", "#{@root}/dups", '/app/spec/fixtures/cached')
#       reorganizer = described_class.new(
#         {
#           existing_dir: "#{@root}/existing",
#           new_dir: "#{@root}/new",
#           dups_dir: "#{@root}/dups",
#           data_dir: cache_dir
#         },
#         system: :linux
#       )
#
#       cmds = reorganizer.call
#       expected = [
#         '# Summary:',
#         '#   Identical files inside new dir: 1',
#         '#   Similar files inside new dir: 0',
#         '#   Doubtful similar files inside new dir: 0',
#         '#   Files in new identical to existing: 0',
#         '#   Files in new similar to existing: 0',
#         '#   Broken files: 0',
#         '#   total: 1',
#         '#',
#         '##################################',
#         '# Identical files inside new dir #',
#         '##################################',
#         "# original: #{@root}/new/x/1.jpg 250x250 (ratio 1.0), size: 8359, 2020-09-13 12:26:40",
#         '# dup: 250x250 (ratio 1.0), size: 8359, distance: 0, 2020-09-13 12:26:40',
#         "mkdir -p '#{@root}/dups/new_inside_full_dups/x'",
#         "mv '#{@root}/new/x/2.jpg' '#{@root}/dups/new_inside_full_dups/x/2.jpg'",
#         ''
#       ]
#       expect(cmds).to eq(expected)
#     end
#   end
#
#   # оба файла в папке new
#   # файлы имеют distance >= 15
#   # > ничего не делаем
#
#
#   # оба файла в папке new
#   # у файлов отличается ratio
#   # > ничего не делаем
#
#   # оба файла в папке new
#   # файлы имеют 8 <= distance < 15
#   # у файлов разный ratio
#   # > ничего не делаем
#
#   # оба файла в папке new
#   # файлы имеют 8 <= distance < 15
#   # у файлов одинаковый ratio (округленный до 1 знака после запятой)
#   # длина видео почти одинаковая (не более 3% разницы)
#   #   среди найденных дубликатов выбираем файл с максимальным разрешением,
#   #   с минимальным размером, с максимальной длиной имени файла
#
#   # оба файла в папке new
#   # файлы имеют distance < 15
#   # у файлов одинаковый ratio (округленный до 1 знака после запятой)
#   # длина видео одинаковая (округление до целой части)
#   #   среди найденных дубликатов выбираем файл с максимальным разрешением,
#   #   с минимальным размером, с максимальной длиной имени файла
#
#   # оба файла в папке new
#   # файлы имеют 8 <= distance < 15
#   # у файлов одинаковый ratio (округленный до 1 знака после запятой)
#   # длина видео сильно отличается
#   # > файл с минимальной длиной имени поместить в папку new_dups_dif_dur
#
#   # mock parse_existing_files method in Reorganizer class
#   # allow_any_instance_of(Reorganizer).to receive(:parse_existing_files).and_return({})
#   # allow_any_instance_of(Reorganizer).to receive(:parse_new_files) do
#   #   {
#   #     "/vt/new/1.mp4" => JSON.parse(File.read('./spec/fixtures/cached/different_similar_phash/1.mp4.json')),
#   #     "/vt/new/1_similar.3gp" => JSON.parse(File.read('./spec/fixtures/cached/different_similar_phash/1_similar.3gp.json'))
#   #   }
#   # end
#   #
# end
#
