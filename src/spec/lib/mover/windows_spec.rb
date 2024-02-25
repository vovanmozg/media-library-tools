require './spec/spec_helper'
require './lib/mover'

describe Mover do
  xit 'converts windows-system inside_new_similar_doubtful' do
    actions = {
      doubtful: [
        type: 'move',
        original: {
          video_length: 57.91,
          phash: 3804812306793776725,
          width: 640,
          height: 640,
          mtime: 1546238794,
          partial_md5: '3671a74c3df57ca174186a8029d9b87d',
          size: 8464175,
          name: '1.mp4',
          relative_path: '/new/x/1.mp4',
          root: '/new',
          real_root: 'C:\\new',
          id: '3671a74c3df57ca174186a8029d9b87d 8464175 1.mp4'
        },
        from: {
          type: 'video',
          video_length: 59.048,
          phash: 16484718488333250133,
          width: 480,
          height: 480,
          mtime: 1543791499,
          partial_md5: '2510fd0e1eb11a54a005d6ebd7b5ab42',
          size: 5708740,
          name: '2.mp4',
          full_path: '/new/x/2.mp4',
          real_path: 'C:\\new\\x\\2.mp4',
          id: '2510fd0e1eb11a54a005d6ebd7b5ab42 5708740 2.mp4'
        },
        to: '/dups/new_inside_similar_doubtful/x/2.mp4',
      ]
    }

    converter = described_class.new(
      :windows,
    # new_dir: '/new',
    # dups_dir: '/dups',
    # real_new_dir: 'C:\\new',
    # real_dups_dir: 'C:\\dups'
      )
    cmds = converter.call(operations: actions)
    expected = [
      ':: Summary:',
      '::   Identical files inside new dir: 0',
      '::   Similar files inside new dir: 0',
      '::   Doubtful similar files inside new dir: 1',
      '::   Files in new identical to existing: 0',
      '::   Files in new similar to existing: 0',
      '::   Broken files: 0',
      '::   total: 1',
      '::',
      ':: #########################################',
      ':: # Doubtful similar files inside new dir #',
      ':: #########################################',
      ':: original: C:\\new\\x\\1.mp4 len: 57.91, 640x640 (ratio 1.0), size: 8464175, 2018-12-31 06:46:34',
      ':: dup: len: 59.048, 480x480 (ratio 1.0), size: 5708740, distance: 14, 2018-12-02 22:58:19',
      'if not exist "C:\\dups\\new_inside_similar_doubtful" mkdir "C:\\dups\\new_inside_similar_doubtful"',
      'if not exist "C:\\dups\\new_inside_similar_doubtful\\x" mkdir "C:\\dups\\new_inside_similar_doubtful\\x"',
      'move "C:\\new\\x\\2.mp4" "C:\\dups\\new_inside_similar_doubtful\\x\\2.mp4"',
      '',
    ]
    expect(cmds).to match_array(expected)
  end
end
