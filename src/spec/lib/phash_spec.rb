require 'spec_helper'
require './lib/phash'

describe PHashImage do
  it 'returns data with imagemagic' do
    file_name = './spec/fixtures/media/1.jpg'
    phash = PHashImage.new
    actual = phash.get_file_info(file_name)
    expected = {
      type: 'image',
      phash: 10787907979500066548,
      width: 250,
      height: 250,
      mtime: 1542905014
    }
    expect(actual).to eq(expected)
  end

  it 'returns data if imagemagic fails' do
    file_name = './spec/fixtures/media/6 broken.jpg'
    phash = PHashImage.new

    expect { phash.get_file_info(file_name) }.to raise_error(ImageReadingError)
  end
end
