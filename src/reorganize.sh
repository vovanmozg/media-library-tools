#!/bin/bash
# Example
# docker run --rm --name media_tools -u=$UID:$UID
#   -v /mnt/papamedia/@personal:/vt/existing
#   -v /mnt/papamedia/media-new/takeout-vova:/vt/new
#   -v /mnt/papamedia/duplicates:/vt/dups
#   -v /mnt/papamedia/data:/vt/data vovan/media_tools ./reorganize.sh

ruby ./bin/reorganize.rb "$@"
