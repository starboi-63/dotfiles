#!/bin/bash

battery=(
  script="$PLUGIN_DIR/battery.sh"
  icon.font="$FONT:Light:19.0"
  label.font="$FONT:Semibold:12.0"
  padding_right=3
  padding_left=0
  label.drawing=on
  update_freq=120
  updates=on
)

sketchybar --add item battery right      \
           --set battery "${battery[@]}" \
           --subscribe battery power_source_change system_woke
