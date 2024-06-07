#!/bin/bash

# Get the current date and time in the desired format
current_date=$(date '+%a %b %-d')
current_hour=$(date '+%-I')
current_time=$(date '+%-I:%M %p')

# Default label width for single-digit hours
label_width=64

# Adjust the width if necessary for double-digit hours
if [ $current_hour -ge 10 ]; then
  label_width=70
fi

# Set the SketchyBar item with the formatted date and time
sketchybar --set $NAME icon="$current_date" label="$current_time" label.width=$label_width
