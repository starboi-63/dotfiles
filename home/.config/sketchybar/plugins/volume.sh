#!/bin/bash

source "$CONFIG_DIR/constants.sh"
WIDTH=$VOLUME_BAR_WIDTH

# Function to read the current media max_chars from a file
read_max_chars() {
  cat "$MAX_CHARS_FILE"
}

# Function to write the current media max_chars to a file
write_max_chars() {
  echo "$1" > "$MAX_CHARS_FILE"
}

volume_change() {
  source "$CONFIG_DIR/icons.sh"
  case $INFO in
    [6-9][0-9]|100) ICON=$VOLUME_100
    ;;
    [3-5][0-9]) ICON=$VOLUME_66
    ;;
    [1-2][0-9]) ICON=$VOLUME_33
    ;;
    [1-9]) ICON=$VOLUME_10
    ;;
    0) ICON=$VOLUME_0
    ;;
    *) ICON=$VOLUME_100
  esac

  sketchybar --set volume_icon label=$ICON \
             --set $NAME slider.percentage=$INFO

  INITIAL_WIDTH="$(sketchybar --query $NAME | jq -r ".slider.width")"
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    CURRENT_CHARS=$(read_max_chars)
    NEW_CHARS=$((CURRENT_CHARS - VOLUME_SHRINK))

    sketchybar --animate tanh 30 --set $NAME slider.width=$WIDTH \
               --set media label.max_chars=$NEW_CHARS

    write_max_chars $NEW_CHARS
  fi

  sleep 2

  # Check wether the volume was changed another time while sleeping
  FINAL_PERCENTAGE="$(sketchybar --query $NAME | jq -r ".slider.percentage")"
  if [ "$FINAL_PERCENTAGE" -eq "$INFO" ]; then
    CURRENT_CHARS=$(read_max_chars)
    NEW_CHARS=$((CURRENT_CHARS + VOLUME_SHRINK))

    sketchybar --animate tanh 30 --set $NAME slider.width=0
    sleep 0.3
    sketchybar --set media label.max_chars=$NEW_CHARS

    write_max_chars $NEW_CHARS
  fi
}

mouse_clicked() {
  osascript -e "set volume output volume $PERCENTAGE"
}

case "$SENDER" in
  "volume_change") volume_change
  ;;
  "mouse.clicked") mouse_clicked
  ;;
esac
