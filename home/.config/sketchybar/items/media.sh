#!/bin/bash

source "$CONFIG_DIR/constants.sh"

media=(
  padding_left=12
  padding_right=4
  icon.background.drawing=on
  icon.background.image=media.artwork
  icon.background.image.corner_radius=3
  icon.background.image.scale=0.8
  script="$PLUGIN_DIR/media.sh"
  label.padding_left=6
  label.max_chars=$MEDIA_MAX_CHARS
  scroll_texts=on
  updates=on
  position=e
)

sketchybar --add item media center \
           --set media "${media[@]}" \
           --subscribe media media_change