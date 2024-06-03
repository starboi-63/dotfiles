#!/bin/bash

sketchybar --set $NAME icon="$(date '+%a %b %-d')" label="$(date '+%-H'):$(date '+%M') $(date '+%p')"
