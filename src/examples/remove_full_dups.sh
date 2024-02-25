#!/bin/bash

docker run -it --rm --name media_tools \
  -v /home/vp/pro/media-library-tools/src:/app \
  -v /media/all/new:/vt/new \
  -v /media/all/data:/vt/data \
  -u=$UID:$UID \
  -e LOG_LEVEL=Logger::DEBUG \
  vovan/media_tools ruby ./bin/read_meta.rb --media_meta_file=1.json --media_dir=/vt/new


