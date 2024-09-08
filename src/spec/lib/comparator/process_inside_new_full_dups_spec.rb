# frozen_string_literal: true

require './spec/spec_helper'
require './lib/comparator/process_inside_new_full_dups'
require './lib/log'

describe ProcessInsideNewFullDups do
  subject { described_class.new('/new', '/dups', LOG) }

  describe '#dups_groups' do
    let(:data) do
      {
        'x/1 identical.jpg' => {
          phash: 10_787_907_979_500_066_548,
          md5: '63f3c713a01010bbcafdfafa3d688566',
          name: '1 identical.jpg',
          root: '/new'
        },
        'x/1.jpg' => {
          phash: 10_787_907_979_500_066_548,
          md5: '63f3c713a01010bbcafdfafa3d688566',
          name: '1.jpg',
          root: '/new'
        }
      }
    end

    it 'returns one file in new_inside_full_dups' do
      _, new_inside_full_dups, = subject.send(:dups_groups, data)

      expected = {
        'x/1.jpg' => {
          original: 'x/1 identical.jpg'
        }
      }
      expect(new_inside_full_dups).to eq(expected)
    end

    it 'returns one processed file' do
      processed_files, = subject.send(:dups_groups, data)
      expect(processed_files).to eq(['x/1.jpg'])
    end

    it 'returns no errors' do
      _, _, errors = subject.send(:dups_groups, data)
      expect(errors).to eq([])
    end

    it 'returns error' do
      data = {
        'x/1 identical.jpg' => {
          phash: 10_787_907_979_500_066_548,
          md5: '63f3c713a01010bbcafdfafa3d688566',
          root: '/new'
        },
        'x/1.jpg' => {
          phash: 55_555_555_555_555_555_555,
          md5: '63f3c713a01010bbcafdfafa3d688566',
          root: '/new'
        }
      }
      _, _, error_files = subject.send(:dups_groups, data)
      expect(error_files).to eq(['x/1 identical.jpg', 'x/1.jpg'])
    end
  end

  it 'returns only one file with biggest filename' do
    image1 = {
      type: 'image',
      phash: 10_787_907_979_500_066_548,
      width: 250,
      height: 250,
      md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1 identical.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1 identical.jpg',
      root: '/new'
    }
    image2 = {
      type: 'image',
      phash: 10_787_907_979_500_066_548,
      width: 250,
      height: 250,
      md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1.jpg',
      root: '/new'
    }
    files_to_processing = {
      'x/1 identical.jpg' => image1,
      'x/1.jpg' => image2
    }

    expected = {
      inside_new_full_dups: [
        {
          type: 'move',
          from: image2.merge(relative_path: 'x/1.jpg'),
          to: { root: '/dups', relative_path: 'new_inside_full_dups/x/1.jpg' },
          original: image1.merge(relative_path: 'x/1 identical.jpg')
        }
      ]
    }
    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/1.jpg'])
    expect(error_files).to eq([])
  end

  it 'returns only one oldest file' do
    image1 = {
      type: 'image',
      phash: 10_787_907_979_500_066_548,
      width: 250,
      height: 250,
      md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1-1.jpg',
      mtime: 1_600_000_001,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1-1.jpg',
      root: '/new'
    }
    image2 = {
      type: 'image',
      phash: 10_787_907_979_500_066_548,
      width: 250,
      height: 250,
      md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1-2.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1-2.jpg',
      root: '/new'
    }
    files_to_processing = {
      'x/1-1.jpg' => image1,
      'x/1-2.jpg' => image2
    }

    expected = {
      inside_new_full_dups: [
        {
          type: 'move',
          from: image1.merge(relative_path: 'x/1-1.jpg'),
          to: { root: '/dups', relative_path: 'new_inside_full_dups/x/1-1.jpg' },
          original: image2.merge(relative_path: 'x/1-2.jpg')
        }
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/1-1.jpg'])
    expect(error_files).to eq([])
  end
end
