#!/bin/bash

sketchybar --set $NAME icon="$(date '+%a %b %-d')" label="$(($(date '+%H') % 12)):$(date '+%M') $(date '+%p')"
