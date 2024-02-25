# frozen_string_literal: true

require './spec/spec_helper'
require './lib/comparator/process_inside_new_doubtful'
require './lib/log'

describe ProcessInsideNewDoubtful do
  subject { described_class.new('/new', '/dups', LOG) }

  # Если phash отличается сильно, значит не дубликат
  it 'returns empty list if phash differs a lot' do
    files_to_processing = {
      'x/1.jpg' => image,
      'x/2.jpg' => image(name: '2.jpg', phash: 787_907_979_500_066_548)
    }

    expected = {
      inside_new_doubtful: []
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq([])
    expect(error_files).to eq([])
  end

  # Если ratio отличается, значит видео разные
  it 'returns empty list if ratio differs a lot' do
    files_to_processing = {
      'x/1.jpg' => image,
      'x/2.jpg' => image(name: '2.jpg', width: 300)
    }

    expected = {
      inside_new_doubtful: []
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq([])
    expect(error_files).to eq([])
  end

  # есть несколько фото попарный distance которых < 2, но если их
  # сгруппировать, то между некоторыми парами distance > 2
  # > ничего не делаем
  it 'does not find dups in groups' do
    image1 = image(phash: '000'.to_i(2), name: '1.jpg', width: 300, height: 300)
    image2 = image(phash: '001'.to_i(2), name: '2.jpg')
    image3 = image(phash: '011'.to_i(2), name: '3.jpg')
    image4 = image(phash: '111'.to_i(2), name: '4.jpg')

    files_to_processing = {
      'x/1.jpg' => image1,
      'x/2.jpg' => image2,
      'x/3.jpg' => image3,
      'x/4.jpg' => image4
    }

    expected = {
      inside_new_doubtful: [
        {
          type: 'move',
          original: image1.merge(relative_path: 'x/1.jpg'),
          from: image2.merge(relative_path: 'x/2.jpg'),
          to: { root: '/dups', relative_path: 'new_inside_doubtful/x/2.jpg' }
        },
        {
          type: 'move',
          original: image1.merge(relative_path: 'x/1.jpg'),
          from: image3.merge(relative_path: 'x/3.jpg'),
          to: { root: '/dups', relative_path: 'new_inside_doubtful/x/3.jpg' }
        }
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(%w[x/2.jpg x/3.jpg])
    expect(error_files).to eq([])
  end

  # Файл с самым большим разрешением при прочих равных считается оригиналом
  it 'makes file with largest dimensions as original' do
    image1 = image
    image2 = image(name: '2.jpg', width: 300, height: 300)
    files_to_processing = {
      'x/1.jpg' => image1,
      'x/2.jpg' => image2
    }

    expected = {
      inside_new_doubtful: [
        type: 'move',
        original: image2.merge(relative_path: 'x/2.jpg'),
        from: image1.merge(relative_path: 'x/1.jpg'),
        to: { root: '/dups', relative_path: 'new_inside_doubtful/x/1.jpg' }
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/1.jpg'])
    expect(error_files).to eq([])
  end

  # Если длина видео отличается более чем на 5%, значит разные
  it 'returns empty list if length differs a lot' do
    files_to_processing = {
      '/new/x/1.mp4' => video,
      '/new/x/2.mp4' => video(name: '2.mp4', video_length: 5.44)
    }

    expected = {
      inside_new_doubtful: []
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq([])
    expect(error_files).to eq([])
  end

  # Если phash отличается незначительно (<= 2),
  # и длина видео отличается менее чем на 5%
  # и ratio такое же
  # значит сомнительный дубликат
  it 'returns longest video if duplicates with slightly different length' do
    video1 = video
    video2 = video(name: '2.mp4', video_length: 4.4)
    files_to_processing = {
      'x/1.mp4' => video1,
      'x/2.mp4' => video2
    }

    expected = {
      inside_new_doubtful: [
        type: 'move',
        original: video1.merge(relative_path: 'x/1.mp4'),
        from: video2.merge(relative_path: 'x/2.mp4'),
        to: { root: '/dups', relative_path: 'new_inside_doubtful/x/2.mp4' }
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/2.mp4'])
    expect(error_files).to eq([])
  end

  # Если phash distance от 2 до 4 и при этом длина одинаковая
  # и длина видео сопадает
  # и ratio такое же
  # значит дубликат
  it 'returns action if duplicates with phash = 3' do
    video1 = video
    video2 = video(name: '2.mp4', phash: 1_000_002)
    files_to_processing = {
      'x/1.mp4' => video1,
      'x/2.mp4' => video2
    }

    expected = {
      inside_new_doubtful: [
        type: 'move',
        from: video1.merge(relative_path: 'x/1.mp4'),
        to: { root: '/dups', relative_path: 'new_inside_doubtful/x/1.mp4' },
        original: video2.merge(relative_path: 'x/2.mp4')
      ]
    }

    actions, processed_new_files, error_files = subject.call(files_to_processing)
    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/1.mp4'])
    expect(error_files).to eq([])
  end
end
