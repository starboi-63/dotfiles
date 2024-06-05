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

update() {
  source "$CONFIG_DIR/icons.sh"
  SSID="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F ' SSID: '  '/ SSID: / {print $2}')"
  IP="$(ipconfig getifaddr en0)"

  ICON="$([ -n "$IP" ] && echo "$WIFI_CONNECTED" || echo "$WIFI_DISCONNECTED")"
  LABEL="$([ -n "$IP" ] && echo "$SSID ($IP)" || echo "Disconnected")"

  sketchybar --set $NAME icon="$ICON" label="$LABEL"
}

click() {
  CURRENT_WIDTH="$(sketchybar --query $NAME | jq -r .label.width)"

  if [ "$CURRENT_WIDTH" -eq "0" ]; then
    WIDTH=dynamic
    CURRENT_CHARS=$(read_max_chars)
    NEW_CHARS=$((CURRENT_CHARS - WIFI_SHRINK))
    sketchybar --set media label.max_chars=$NEW_CHARS \
               --animate sin 20 --set $NAME label.width="$WIDTH"
    write_max_chars $NEW_CHARS
  else
    WIDTH=0
    CURRENT_CHARS=$(read_max_chars)
    NEW_CHARS=$((CURRENT_CHARS + WIFI_SHRINK))
    sketchybar --animate sin 20 --set $NAME label.width="$WIDTH"
    sleep 0.2
    sketchybar --set media label.max_chars=$NEW_CHARS
    write_max_chars $NEW_CHARS
  fi
}

case "$SENDER" in
  "wifi_change") update
  ;;
  "mouse.clicked") click
  ;;
esac
