# frozen_string_literal: true

require './spec/spec_helper'
require './lib/comparator/process_inside_new_similar'
require './lib/log'

describe ProcessInsideNewSimilar do
  subject { described_class.new('/new', '/dups', LOG) }

  describe '#dups_groups' do
    # phash одинаковый, значит дубликаты
    it 'returns one file in new_inside_full_dups' do
      data = {
        'x/1 identical.jpg' => {
          phash: 10_787_907_979_500_066_548,
          md5: '63f3c713a01010bbcafdfafa3d688566',
          mtime: 1_600_000_000,
          name: '1 identical.jpg'
        },
        'x/1.jpg' => {
          phash: 10_787_907_979_500_066_548,
          md5: '63f3c713a01010bbcafdfafa3d688566',
          mtime: 1_600_000_000,
          name: '1.jpg'
        }
      }
      _, new_inside_full_dups, = subject.send(:dups_groups, data)

      expected = {
        'x/1.jpg' => {
          original: 'x/1 identical.jpg'
        }
      }
      expect(new_inside_full_dups).to eq(expected)
    end
  end

  # Самый новый файл при прочих равных считаем дубликатом
  it 'returns action where image2 is dup' do
    image1 = {
      type: 'image',
      phash: 10_787_907_979_500_066_548,
      width: 250,
      height: 250,
      md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1.jpg',
      mtime: 1_600_000_001,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1.jpg'
    }
    image2 = {
      type: 'image',
      phash: 10_787_907_979_500_066_548,
      width: 250,
      height: 250,
      md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '2.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 2.jpg'
    }
    files_to_processing = {
      'x/1.jpg' => image1,
      'x/2.jpg' => image2
    }
    expected = {
      inside_new_similar: [
        type: 'move',
        original: image2.merge(relative_path: 'x/2.jpg'),
        from: image1.merge(relative_path: 'x/1.jpg'),
        to: { root: '/dups', relative_path: 'new_inside_similar/x/1.jpg' }
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/1.jpg'])
    expect(error_files).to eq([])
  end

  #
  # it 'returns one file in new_inside_full_dups' do
  #   data = {
  #     '/new/1 identical.jpg' => {
  #       phash: 10787907979500066548,
  #       md5: '63f3c713a01010bbcafdfafa3d688566',
  #       mtime: 1_600_000_001,
  #       name: '1 identical.jpg'
  #     },
  #     '/new/1.jpg' => {
  #       phash: 10787907979500066548,
  #       md5: '63f3c713a01010bbcafdfafa3d688566',
  #       mtime: 1_600_000_000,
  #       name: '1.jpg'
  #     }
  #   }
  #   _, new_inside_full_dups, _ = subject.send(:dups_groups, data)
  #
  #   expected = {
  #     '/new/1.jpg' => {
  #       original: '/new/1 identical.jpg'
  #     }
  #   }
  #   expect(new_inside_full_dups).to eq(expected)
  # end
end
