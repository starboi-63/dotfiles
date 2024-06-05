#!/bin/bash

# Width of the volume bar when expanded
export VOLUME_BAR_WIDTH=63

# Parameters controlling the length of the media label
export MEDIA_MAX_CHARS=16                                   # Maximum number of characters in media label
export VOLUME_SHRINK=6                                      # Amount to subtract if volume is extended
export WIFI_SHRINK=8                                        # Amount to subtract if wifi is extended
export MAX_CHARS_FILE="/tmp/sketchybar_media_max_chars.txt" # File to store the current max chars

# Initialize the temporary file with the default media max_chars value if it doesn't exist
# NOTE: if 'MEDIA_MAX_CHARS' is modified, the file should be deleted to apply the new value
if [ ! -f "$MAX_CHARS_FILE" ]; then
  echo "$MEDIA_MAX_CHARS" > "$MAX_CHARS_FILE"
fi