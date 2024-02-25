# frozen_string_literal: true

require 'json'
require './spec/spec_helper'
require './lib/comparator/process_full_dups'
require './lib/log'

describe ProcessFullDups do
  subject { described_class.new('/new', '/existing', '/dups', LOG) }

  it 'returns files from new which exists in existing' do
    image1 = image(name: '1 identical.jpg', phash: 11_111_111_111_111_111_111,
                   partial_md5: '1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f', root: '/new')
    image2 = image(name: '2.jpg', phash: 22_222_222_222_222_222_222, partial_md5: '25252525252525252525252525252525',
                   root: '/new')
    new_data = {
      'x/1 identical.jpg' => image1,
      'x/2.jpg' => image2
    }

    image3 = image(name: '1.jpg', phash: 11_111_111_111_111_111_111, partial_md5: '1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f',
                   root: '/existing')
    image4 = image(name: '2.jpg', phash: 33_333_333_333_333_333_333, partial_md5: '3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f',
                   root: '/existing')
    existing_data = {
      'x/1.jpg' => image3,
      'x/3.jpg' => image4
    }

    expected = {
      full_dups: [
        {
          type: 'move',
          from: image1.merge(relative_path: 'x/1 identical.jpg'),
          to: { root: '/dups', relative_path: 'full_dups/x/1 identical.jpg' },
          original: image3.merge(relative_path: 'x/1.jpg')
        }
      ]
    }

    actions, processed_new_files = subject.call(new_data, existing_data)

    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['x/1 identical.jpg'])
  end
end
