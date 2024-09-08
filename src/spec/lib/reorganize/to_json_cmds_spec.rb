# frozen_string_literal: true
# require './spec/spec_helper'
# require './lib/reorganize/to_json_cmds'
#
# describe ToJsonCmds do
#
#
#   it 'converts inside_new_full_dups' do
#     actions = {
#       inside_new_full_dups: [
#         {
#           type: 'move',
#           original: {
#             type: 'video',
#             phash: 10787907979500066548,
#             width: 250,
#             height: 250,
#             md5: '63f3c713a01010bbcafdfafa3d688566',
#             size: 8359,
#             video_length: 4.4,
#             name: '1 another identical.mp4',
#             full_path: '/vt/new/x/1 another identical.mp4',
#             mtime: 1_600_000_000,
#             id: '63f3c713a01010bbcafdfafa3d688566 8359 1 another identical.mp4'
#           },
#           from: {
#             type: 'video',
#             phash: 10787907979500066547,
#             width: 250,
#             height: 250,
#             md5: '63f3c713a01010bbcafdfafa3d688566',
#             size: 8359,
#             video_length: 4.4,
#             name: '1.mp4',
#             full_path: '/vt/new/x/1.mp4',
#             mtime: 1_600_000_000,
#             id: '63f3c713a01010bbcafdfafa3d688566 8359 1.mp4'
#           },
#           to: '/vt/dups/new_inside_full_dups/x/1.mp4',
#         },
#         {
#           type: 'move',
#           original: {
#             type: 'video',
#             phash: 10787907979500066548,
#             width: 250,
#             height: 250,
#             md5: '63f3c713a01010bbcafdfafa3d688566',
#             size: 8359,
#             video_length: 4.4,
#             name: '1 another identical.mp4',
#             full_path: '/vt/new/x/1 another identical.mp4',
#             mtime: 1_600_000_000,
#             id: '63f3c713a01010bbcafdfafa3d688566 8359 1 another identical.mp4'
#           },
#           from: {
#             type: 'video',
#             phash: 10787907979500066547,
#             width: 250,
#             height: 250,
#             md5: '63f3c713a01010bbcafdfafa3d688566',
#             size: 8359,
#             video_length: 4.4,
#             name: '1 identical.mp4',
#             full_path: '/vt/new/x/1 identical.mp4',
#             mtime: 1_600_000_000,
#             id: '63f3c713a01010bbcafdfafa3d688566 8359 1 identical.mp4'
#           },
#           to: '/vt/dups/new_inside_full_dups/x/1 identical.mp4',
#         }
#       ]
#     }
#
#
#
#     cmds = described_class.new(system: :linux).process(actions_groups: actions)
#     expected  = <<~STR
# {
#   "inside_new_full_dups": [
#     {
#       "type": "move",
#       "original": {
#         "type": "video",
#         "phash": 10787907979500066548,
#         "width": 250,
#         "height": 250,
#         "md5": "63f3c713a01010bbcafdfafa3d688566",
#         "size": 8359,
#         "video_length": 4.4,
#         "name": "1 another identical.mp4",
#         "full_path": "/vt/new/x/1 another identical.mp4",
#         "mtime": 1600000000,
#         "id": "63f3c713a01010bbcafdfafa3d688566 8359 1 another identical.mp4",
#         "real_path": "/vt/new/x/1 another identical.mp4",
#         "date": "2020-09-13 12:26:40",
#         "ratio": 1.0
#       },
#       "from": {
#         "type": "video",
#         "phash": 10787907979500066547,
#         "width": 250,
#         "height": 250,
#         "md5": "63f3c713a01010bbcafdfafa3d688566",
#         "size": 8359,
#         "video_length": 4.4,
#         "name": "1.mp4",
#         "full_path": "/vt/new/x/1.mp4",
#         "mtime": 1600000000,
#         "id": "63f3c713a01010bbcafdfafa3d688566 8359 1.mp4"
#       },
#       "to": "/vt/dups/new_inside_full_dups/x/1.mp4",
#       "dup": {
#         "distance": 3,
#         "date": "2020-09-13 12:26:40",
#         "ratio": 1.0,
#         "real_path": "/vt/dups/new_inside_full_dups/x/1.mp4"
#       }
#     },
#     {
#       "type": "move",
#       "original": {
#         "type": "video",
#         "phash": 10787907979500066548,
#         "width": 250,
#         "height": 250,
#         "md5": "63f3c713a01010bbcafdfafa3d688566",
#         "size": 8359,
#         "video_length": 4.4,
#         "name": "1 another identical.mp4",
#         "full_path": "/vt/new/x/1 another identical.mp4",
#         "mtime": 1600000000,
#         "id": "63f3c713a01010bbcafdfafa3d688566 8359 1 another identical.mp4",
#         "real_path": "/vt/new/x/1 another identical.mp4",
#         "date": "2020-09-13 12:26:40",
#         "ratio": 1.0
#       },
#       "from": {
#         "type": "video",
#         "phash": 10787907979500066547,
#         "width": 250,
#         "height": 250,
#         "md5": "63f3c713a01010bbcafdfafa3d688566",
#         "size": 8359,
#         "video_length": 4.4,
#         "name": "1 identical.mp4",
#         "full_path": "/vt/new/x/1 identical.mp4",
#         "mtime": 1600000000,
#         "id": "63f3c713a01010bbcafdfafa3d688566 8359 1 identical.mp4"
#       },
#       "to": "/vt/dups/new_inside_full_dups/x/1 identical.mp4",
#       "dup": {
#         "distance": 3,
#         "date": "2020-09-13 12:26:40",
#         "ratio": 1.0,
#         "real_path": "/vt/dups/new_inside_full_dups/x/1 identical.mp4"
#       }
#     }
#   ]
# }
#     STR
#
#
#     expect(cmds).to eq(expected)
#   end
#
#   it 'converts inside_new_similar' do
#     actions = {
#       inside_new_similar: [
#         type: 'move',
#         original: {
#           type: 'video',
#           phash: 10787907979500066548,
#           width: 250,
#           height: 250,
#           md5: '63f3c713a01010bbcafdfafa3d688566',
#           size: 8359,
#           video_length: 4.4,
#           name: '1.mp4',
#           full_path: '/new/x/1.mp4',
#           mtime: 1_600_000_000,
#           id: '63f3c713a01010bbcafdfafa3d688566 8359 1.mp4'
#         },
#         from: {
#           type: 'video',
#           phash: 10787907979500066547,
#           width: 250,
#           height: 250,
#           md5: '63f3c713a01010bbcafdfafa3d688566',
#           size: 8359,
#           video_length: 4.4,
#           name: '2.mp4',
#           full_path: '/new/x/2.mp4',
#           mtime: 1_600_000_000,
#           id: '63f3c713a01010bbcafdfafa3d688566 8359 2.mp4'
#         },
#         to: '/dups/new_inside_similar/x/2.mp4',
#       ]
#     }
#
#     cmds = described_class.new(system: :linux).process(actions_groups: actions)
#     expected = [
#       '# Summary:',
#       '#   Identical files inside new dir: 0',
#       '#   Similar files inside new dir: 1',
#       '#   Doubtful similar files inside new dir: 0',
#       '#   Files in new identical to existing: 0',
#       '#   Files in new similar to existing: 0',
#       '#   Broken files: 0',
#       '#   total: 1',
#       '#',
#       '################################',
#       '# Similar files inside new dir #',
#       '################################',
#       '# original: /new/x/1.mp4 len: 4.4, 250x250 (ratio 1.0), size: 8359, 2020-09-13 12:26:40',
#       '# dup: len: 4.4, 250x250 (ratio 1.0), size: 8359, distance: 3, 2020-09-13 12:26:40',
#       "mkdir -p '/dups/new_inside_similar/x'",
#       "mv '/new/x/2.mp4' '/dups/new_inside_similar/x/2.mp4'",
#       '',
#     ]
#
#     expect(cmds).to eq(expected)
#   end
#
#   it 'converts inside_new_similar_doubtful' do
#     actions = {
#       inside_new_doubtful: [
#         type: 'move',
#         original: {
#           video_length: 57.91,
#           phash: 3804812306793776725,
#           width: 640,
#           height: 640,
#           mtime: 1546238794,
#           md5: '3671a74c3df57ca174186a8029d9b87d',
#           size: 8464175,
#           name: '1.mp4',
#           full_path: '/new/x/1.mp4',
#           id: '3671a74c3df57ca174186a8029d9b87d 8464175 1.mp4'
#         },
#         from: {
#           type: 'video',
#           video_length: 59.048,
#           phash: 16484718488333250133,
#           width: 480,
#           height: 480,
#           mtime: 1543791499,
#           md5: '2510fd0e1eb11a54a005d6ebd7b5ab42',
#           size: 5708740,
#           name: '2.mp4',
#           full_path: '/new/x/2.mp4',
#           id: '2510fd0e1eb11a54a005d6ebd7b5ab42 5708740 2.mp4'
#         },
#         to: '/dups/new_inside_similar_doubtful/x/2.mp4',
#       ]
#     }
#
#     cmds = described_class.new(system: :linux).process(actions_groups: actions)
#     expected = [
#       '# Summary:',
#       '#   Identical files inside new dir: 0',
#       '#   Similar files inside new dir: 0',
#       '#   Doubtful similar files inside new dir: 1',
#       '#   Files in new identical to existing: 0',
#       '#   Files in new similar to existing: 0',
#       '#   Broken files: 0',
#       '#   total: 1',
#       '#',
#       '#########################################',
#       '# Doubtful similar files inside new dir #',
#       '#########################################',
#       '# original: /new/x/1.mp4 len: 57.91, 640x640 (ratio 1.0), size: 8464175, 2018-12-31 06:46:34',
#       '# dup: len: 59.048, 480x480 (ratio 1.0), size: 5708740, distance: 14, 2018-12-02 22:58:19',
#       "mkdir -p '/dups/new_inside_similar_doubtful/x'",
#       "mv '/new/x/2.mp4' '/dups/new_inside_similar_doubtful/x/2.mp4'",
#       '',
#     ]
#
#     expect(cmds).to eq(expected)
#   end
#
#   it 'converts windows-system inside_new_similar_doubtful' do
#     actions = {
#       inside_new_doubtful: [
#         type: 'move',
#         original: {
#           video_length: 57.91,
#           phash: 3804812306793776725,
#           width: 640,
#           height: 640,
#           mtime: 1546238794,
#           md5: '3671a74c3df57ca174186a8029d9b87d',
#           size: 8464175,
#           name: '1.mp4',
#           full_path: '/new/x/1.mp4',
#           id: '3671a74c3df57ca174186a8029d9b87d 8464175 1.mp4'
#         },
#         from: {
#           type: 'video',
#           video_length: 59.048,
#           phash: 16484718488333250133,
#           width: 480,
#           height: 480,
#           mtime: 1543791499,
#           md5: '2510fd0e1eb11a54a005d6ebd7b5ab42',
#           size: 5708740,
#           name: '2.mp4',
#           full_path: '/new/x/2.mp4',
#           id: '2510fd0e1eb11a54a005d6ebd7b5ab42 5708740 2.mp4'
#         },
#         to: '/dups/new_inside_similar_doubtful/x/2.mp4',
#       ]
#     }
#
#     converter = described_class.new(
#       system: :windows,
#       dirs: {
#         new_dir: '/new',
#         dups_dir: '/dups',
#         real_new_dir: 'C:\\new',
#         real_dups_dir: 'C:\\dups'
#       }
#     )
#     cmds = converter.process(actions_groups: actions)
#     expected = [
#       ':: Summary:',
#       '::   Identical files inside new dir: 0',
#       '::   Similar files inside new dir: 0',
#       '::   Doubtful similar files inside new dir: 1',
#       '::   Files in new identical to existing: 0',
#       '::   Files in new similar to existing: 0',
#       '::   Broken files: 0',
#       '::   total: 1',
#       '::',
#       ':: #########################################',
#       ':: # Doubtful similar files inside new dir #',
#       ':: #########################################',
#       ':: original: C:\\new\\x\\1.mp4 len: 57.91, 640x640 (ratio 1.0), size: 8464175, 2018-12-31 06:46:34',
#       ':: dup: len: 59.048, 480x480 (ratio 1.0), size: 5708740, distance: 14, 2018-12-02 22:58:19',
#       'if not exist "C:\\dups\\new_inside_similar_doubtful" mkdir "C:\\dups\\new_inside_similar_doubtful"',
#       'if not exist "C:\\dups\\new_inside_similar_doubtful\\x" mkdir "C:\\dups\\new_inside_similar_doubtful\\x"',
#       'move "C:\\new\\x\\2.mp4" "C:\\dups\\new_inside_similar_doubtful\\x\\2.mp4"',
#       '',
#     ]
#     expect(cmds).to eq(expected)
#   end
#
#   it 'converts full_dups'
#   it 'converts similar'
# end
