#!/bin/bash

# internal (laptop) display
PRIMARY="eDP-1"
# internal resolution
PRIMARY_RES=$(xrandr | grep -A1 "^$PRIMARY connected" | grep -oP '\d+x\d+' | head -n1)

# set internal display to auto
xrandr --output "$PRIMARY" --auto

# loop through other connected displays and mirror with scaling
for OUTPUT in $(xrandr | grep " connected" | cut -d" " -f1); do
    if [ "$OUTPUT" != "$PRIMARY" ]; then
        xrandr --output "$OUTPUT" --auto --scale-from "$PRIMARY_RES" --same-as "$PRIMARY"
    fi
done
