#!/bin/bash

echo "Examples"
echo "Help"
echo "docker run --rm --name media_tools vovan/media_tools"
echo ""
echo "List of extensions"
echo "docker run --rm --name media_tools -v /home/mediafiles:/app/media -u=\$UID:\$UID vovan/media_tools ./extensions-list.sh"

