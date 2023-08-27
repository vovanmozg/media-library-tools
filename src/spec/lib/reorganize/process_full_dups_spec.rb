require './spec/spec_helper'
require './lib/reorganize/process_full_dups'
require './lib/log'

describe ProcessFullDups do
  subject { described_class.new('/new', '/existing', '/dups', LOG) }

  it 'returns files from new which exists in existing' do
    image1 = image(name: '1 identical.jpg', phash: 11111111111111111111, partial_md5: '1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f')
    image2 = image(name: '2.jpg', phash: 22222222222222222222, partial_md5: '25252525252525252525252525252525')
    new_data = {
      '/new/x/1 identical.jpg' => image1,
      '/new/x/2.jpg' => image2
    }

    image3 = image(name: '1.jpg', phash: 11111111111111111111, partial_md5: '1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f')
    image4 = image(name: '2.jpg', phash: 33333333333333333333, partial_md5: '3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f')
    existing_data = {
      '/existing/x/1.jpg' => image3,
      '/existing/x/3.jpg' => image4
    }

    expected = {
      new_full_dups: [
        {
          type: 'move',
          from: image1.merge(full_path: '/new/x/1 identical.jpg'),
          to: '/dups/new_full_dups/x/1 identical.jpg',
          original: image3.merge(full_path: '/existing/x/1.jpg')
        }
      ]
    }

    actions, processed_new_files = subject.call(new_data, existing_data)

    expect(actions).to eq(expected)
    expect(processed_new_files).to eq(['/new/x/1 identical.jpg'])
  end
end
