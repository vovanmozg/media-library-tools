#!/bin/bash
# Example
# docker run --rm --name media_tools -u=$UID:$UID \
#   -v /mnt/media/images:/vt/media \
#   -v /mnt/media/cache:/vt/cache \
#   -e LOG_LEVEL=Logger::INFO \
#   vovan/media_tools ./collect_phashes.sh --real-media-dir=/mnt/media/images

ruby ./bin/collect_phashes.rb "$@"
