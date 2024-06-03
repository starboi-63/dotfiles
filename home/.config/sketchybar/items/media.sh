media=(
  padding_left=13
  icon.background.drawing=on
  icon.background.image=media.artwork
  icon.background.image.corner_radius=3
  script="$PLUGIN_DIR/media.sh"
  label.max_chars=15
  scroll_texts=on
  updates=on
  position=e
)

sketchybar --add item media center \
           --set media "${media[@]}" \
           --subscribe media media_change
