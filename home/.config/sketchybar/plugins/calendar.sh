#!/bin/bash

# Get the current date and time in the desired format
current_date=$(date '+%a %b %-d')
current_time=$(date '+%-I:%M %p')

# Set the SketchyBar item with the formatted date and time
sketchybar --set $NAME icon="$current_date" label="$current_time"
