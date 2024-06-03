#!/bin/bash

cpu_top=(
  label.font="$FONT:Semibold:7"
  label=CPU
  icon.drawing=off
  width=0
  padding_right=10
  y_offset=8
)

cpu_percent=(
  label.font="$FONT:Heavy:12"
  label=CPU
  y_offset=-4
  padding_right=0
  width=40
  icon.drawing=off
  update_freq=4
  mach_helper="$HELPER"
)

cpu_sys=(
  width=0
  y_offset=2
  graph.color=$RED
  graph.fill_color=$RED
  label.drawing=off
  icon.drawing=off
  background.height=30
  background.drawing=on
  background.color=$TRANSPARENT
)

cpu_user=(
  y_offset=2
  graph.color=$BLUE
  label.drawing=off
  icon.drawing=off
  background.height=30
  background.drawing=on
  background.color=$TRANSPARENT
)

sketchybar --add item cpu.top q                  \
           --set cpu.top "${cpu_top[@]}"         \
                                                 \
           --add item cpu.percent q              \
           --set cpu.percent "${cpu_percent[@]}" \
                                                 \
           --add graph cpu.sys q  75             \
           --set cpu.sys "${cpu_sys[@]}"         \
                                                 \
           --add graph cpu.user q  75            \
           --set cpu.user "${cpu_user[@]}"
