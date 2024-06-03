#!/bin/bash

hour=$(date '+%-H')
if [ $hour -gt 12 ]; then
    hour=$((hour - 12))
fi

sketchybar --set $NAME icon="$(date '+%a %b %-d')" label="$hour:$(date '+%M') $(date '+%p')"
