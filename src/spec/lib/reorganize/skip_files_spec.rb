require './spec/spec_helper'
require './lib/reorganize/skip_files'

describe SkipFiles do
  it 'does not skip normal image' do
    files_to_processing = {
      '/new/x/1' => {
        type: 'image',
        phash: 10787907979500066548,
        width: 250,
        height: 250,
        partial_md5: '63f3c713a01010bbcafdfafa3d688566',
        size: 8359,
        name: '1',
        id: '63f3c713a01010bbcafdfafa3d688566 8359 1'
      }
    }

    skipped_files, actions = described_class.new('/new', '/dups').call(files_to_processing)
    expect(skipped_files).to eq([])
    expect(actions[:skipped]).to eq([])
  end

  it 'skip videos with wrong width or height' do
    files_to_processing = {
      '/new/x/1.mp4' => {
        type: 'video',
        width: 250,
        height: 250
      }
    }

    skipped_files, actions = described_class.new('/new', '/dups').call(files_to_processing)
    expect(skipped_files).to eq(['/new/x/1.mp4'])
    expected = [
      {
        from: "/new/x/1.mp4",
        to: "/dups/new_broken/x/1.mp4",
        type: :wrong_length,
        file_info: {
          type: 'video',
          width: 250,
          height: 250
        }
      }
    ]
    expect(actions[:skipped]).to eq(expected)
  end
end
