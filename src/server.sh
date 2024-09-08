#!/bin/bash
# Example
# docker run --rm --name media_tools -u=$UID:$UID \
#   -v /mnt/papamedia/@personal:/vt/existing \
#   -v /mnt/papamedia/media-new/takeout-vova:/vt/new \
#   -v /mnt/papamedia/duplicates:/vt/duplicates \
#   -v /mnt/papamedia/cache:/vt/cache \
#   vovan/media_tools ./server.sh

rerun --background --no-notify 'ruby ./webserver/app.rb'
# ruby ./webserver/app.rb

