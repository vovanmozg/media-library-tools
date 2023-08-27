#!/bin/bash
# Example
# docker run --rm --name media_tools -u=$UID:$UID
#   -v /mnt/papamedia/@personal:/app/video_existing
#   -v /mnt/papamedia/media-new/takeout-vova:/app/video_new
#   -v /mnt/papamedia/duplicates:/app/duplicates
#   -v /mnt/papamedia/cache:/app/cache vovan/media_tools ./reorganize.sh

ruby ./bin/reorganize.rb "$@"
