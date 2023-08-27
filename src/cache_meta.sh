#!/bin/bash
# Example
# docker run --rm --name media_tools -v /home/mediafiles:/app/videos -v /home/mediacache:/app/cache -u=$UID:$UID vovan/media_tools ./cache-meta.sh

ruby ./bin/cache_meta.rb
