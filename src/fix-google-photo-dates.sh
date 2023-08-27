#!/bin/bash
# Example
# docker run --rm --name media_tools -u=$UID:$UID -v /home/mediafiles:/app/media vovan/media_tools ./fix-google-photo-dates.sh

ruby ./fix-google-photo-dates.rb
