#!/bin/bash

source "$CONFIG_DIR/constants.sh"

# Function to read the current media max_chars from a file
read_max_chars() {
  cat "$MAX_CHARS_FILE"
}

# Function to write the current media max_chars to a file
write_max_chars() {
  echo "$1" > "$MAX_CHARS_FILE"
}

WIDTH=$VOLUME_BAR_WIDTH

detail_on() {
  CURRENT_CHARS=$(read_max_chars)
  NEW_CHARS=$((CURRENT_CHARS - VOLUME_SHRINK))

  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH    \
             --set media label.max_chars=$NEW_CHARS

  write_max_chars $NEW_CHARS
}

detail_off() {
  CURRENT_CHARS=$(read_max_chars)
  NEW_CHARS=$((CURRENT_CHARS + VOLUME_SHRINK))

  sketchybar --animate tanh 30 --set volume slider.width=0
  sleep 0.3
  sketchybar --set media label.max_chars=$NEW_CHARS

  write_max_chars $NEW_CHARS
}

toggle_detail() {
  INITIAL_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    detail_on
  else
    detail_off
  fi
}

toggle_devices() {
  which SwitchAudioSource >/dev/null || exit 0
  source "$CONFIG_DIR/colors.sh"

  args=(--remove '/volume.device\.*/' --set "$NAME" popup.drawing=toggle)
  COUNTER=0
  CURRENT="$(SwitchAudioSource -t output -c)"
  while IFS= read -r device; do
    COLOR=$GREY
    if [ "${device}" = "$CURRENT" ]; then
      COLOR=$WHITE
    fi
    args+=(--add item volume.device.$COUNTER popup."$NAME" \
           --set volume.device.$COUNTER label="${device}" \
                                        label.color="$COLOR" \
                 click_script="SwitchAudioSource -s \"${device}\" && sketchybar --set /volume.device\.*/ label.color=$GREY --set \$NAME label.color=$WHITE --set $NAME popup.drawing=off")
    COUNTER=$((COUNTER+1))
  done <<< "$(SwitchAudioSource -a -t output)"

  sketchybar -m "${args[@]}" > /dev/null
}

if [ "$BUTTON" = "right" ] || [ "$MODIFIER" = "shift" ]; then
  toggle_devices
else
  toggle_detail
fi
