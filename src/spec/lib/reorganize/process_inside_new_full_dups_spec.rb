require './spec/spec_helper'
require './lib/reorganize/process_inside_new_full_dups'
require './lib/log'

describe ProcessInsideNewFullDups do
  subject { described_class.new('/new', '/dups', LOG) }

  describe '#dups_groups' do
    let(:data) do
      {
        '/new/x/1 identical.jpg' => {
          phash: 10787907979500066548,
          partial_md5: '63f3c713a01010bbcafdfafa3d688566',
          name: '1 identical.jpg'
        },
        '/new/x/1.jpg' => {
          phash: 10787907979500066548,
          partial_md5: '63f3c713a01010bbcafdfafa3d688566',
          name: '1.jpg'
        }
      }
    end

    it 'returns one file in new_inside_full_dups' do
      _, new_inside_full_dups, _ = subject.send(:dups_groups, data)

      expected = {
        '/new/x/1.jpg' => {
          original: '/new/x/1 identical.jpg'
        }
      }
      expect(new_inside_full_dups).to eq(expected)
    end

    it 'returns one processed file' do
      processed_files, _, _ = subject.send(:dups_groups, data)
      expect(processed_files).to eq(['/new/x/1.jpg'])
    end

    it 'returns no errors' do
      _, _, errors = subject.send(:dups_groups, data)
      expect(errors).to eq([])
    end

    it 'returns error' do
      data = {
        '/new/x/1 identical.jpg' => {
          phash: 10787907979500066548,
          partial_md5: '63f3c713a01010bbcafdfafa3d688566',
        },
        '/new/x/1.jpg' => {
          phash: 55555555555555555555,
          partial_md5: '63f3c713a01010bbcafdfafa3d688566',
        }
      }
      _, _, error_files = subject.send(:dups_groups, data)
      expect(error_files).to eq(["/new/x/1 identical.jpg", "/new/x/1.jpg"])
    end
  end

  it 'returns only one file with biggest filename' do
    image1 = {
      type: 'image',
      phash: 10787907979500066548,
      width: 250,
      height: 250,
      partial_md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1 identical.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1 identical.jpg',
      full_path: '/new/x/1 identical.jpg'
    }
    image2 = {
      type: 'image',
      phash: 10787907979500066548,
      width: 250,
      height: 250,
      partial_md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1.jpg',
      full_path: '/new/x/1.jpg'
    }
    files_to_processing = {
      '/new/x/1 identical.jpg' => image1,
      '/new/x/1.jpg' => image2
    }

    expected = {
      inside_new_full_dups: [
        {
          type: 'move',
          from: image2.merge(full_path: '/new/x/1.jpg'),
          to: '/dups/new_inside_full_dups/x/1.jpg',
          original: image1.merge(full_path: '/new/x/1 identical.jpg'),
        }
      ]
    }
    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['/new/x/1.jpg'])
    expect(error_files).to eq([])
  end

  it 'returns only one oldest file' do
    image1 = {
      type: 'image',
      phash: 10787907979500066548,
      width: 250,
      height: 250,
      partial_md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1-1.jpg',
      mtime: 1_600_000_001,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1-1.jpg',
      full_path: '/new/x/1-1.jpg'
    }
    image2 = {
      type: 'image',
      phash: 10787907979500066548,
      width: 250,
      height: 250,
      partial_md5: '63f3c713a01010bbcafdfafa3d688566',
      size: 8359,
      name: '1-2.jpg',
      mtime: 1_600_000_000,
      id: '63f3c713a01010bbcafdfafa3d688566 8359 1-2.jpg',
      full_path: '/new/x/1-2.jpg'
    }
    files_to_processing = {
      '/new/x/1-1.jpg' => image1,
      '/new/x/1-2.jpg' => image2
    }

    expected = {
      inside_new_full_dups: [
        {
          type: 'move',
          from: image1.merge(full_path: '/new/x/1-1.jpg'),
          to: '/dups/new_inside_full_dups/x/1-1.jpg',
          original: image2.merge(full_path: '/new/x/1-2.jpg'),
        }
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['/new/x/1-1.jpg'])
    expect(error_files).to eq([])
  end
end
