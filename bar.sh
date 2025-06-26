#!/bin/dash

# ^c$var^ = fg color
# ^b$var^ = bg color

interval=0

# load colors
. ~/.config/chadwm/scripts/bar_themes/catppuccin

cpu() {
  cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)

  printf "^c$black^ ^b$green^ CPU"
  printf "^c$white^ ^b$grey^ $cpu_val"
}

pkg_updates() {
  #updates=$({ timeout 20 doas xbps-install -un 2>/dev/null || true; } | wc -l) # void
  updates=$({ timeout 20 checkupdates 2>/dev/null || true; } | wc -l) # arch
  # updates=$({ timeout 20 aptitude search '~U' 2>/dev/null || true; } | wc -l)  # apt (ubuntu, debian etc)

  if [ -z "$updates" ]; then
    printf "  ^c$green^    Fully Updated"
  else
    printf "  ^c$green^    $updates"" updates"
  fi
}

battery() {
  get_capacity="$(cat /sys/class/power_supply/BAT1/capacity)"
  printf "^c$blue^   $get_capacity"
}


brightness() {
  # Read the raw brightness value from the file
  raw=$(cat /sys/class/backlight/*/brightness)
  
  # Scale from 0-96000 to 0-100 using the formula: (value * 100) / 96000
  # We multiply by 100 first to maintain precision before division
  scaled=$(printf "%.0f" $(echo "$raw * 100 / 96000" | bc -l))
  
  # Print the icon and scaled brightness value
  printf "^c$red^ "
  printf "^c$red^%d\n" "$scaled"
}

mem() {
  printf "^c$blue^^b$black^  "
  printf "^c$blue^ $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
}


check_network() {
    # Check if Wi-Fi is up
    wifi_operstate=$(cat /sys/class/net/wl*/operstate 2>/dev/null)
    if [ "$wifi_operstate" = "up" ]; then
        # Get Wi-Fi SSID
        ssid=$(iwgetid -r 2>/dev/null)
        if [ -n "$ssid" ]; then
            echo "$ssid"
        else
            echo "Wi-Fi connected, but SSID not available"
        fi
    else
        # Check if Ethernet is up
        ethernet_operstate=$(cat /sys/class/net/en*/operstate 2>/dev/null)
        if [ "$ethernet_operstate" = "up" ]; then
            # Get Ethernet IP address
            ip=$(ip -4 addr show enp11s0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
            if [ -n "$ip" ]; then
                echo " $ip"
            else
                echo "Ethernet connected, but IP address not available"
            fi
        else
            echo "No network connection"
        fi
    fi
}


get_current_ip() {
    for iface in /sys/class/net/*; do
        iface=$(basename "$iface")

        # Skip loopback interface and VPNs
        if [ "$iface" = "lo" ] || [[ "$(ip -4 addr show "$iface" 2>/dev/null)" =~ "peer" ]]; then
            continue
        fi

        operstate=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)
        if [ "$operstate" = "up" ]; then
            ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
            if [ -n "$ip" ]; then
                echo "$ip"
                return 0
            fi
        fi
    done

    echo "No active network connection"
    return 1
}

volume() {
  # Fetch the default sink volume using pactl
  volume=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}')
  muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

  if [ "$muted" = "yes" ]; then
    printf "^c$red^  Muted"
  else
    printf "^c$green^   %s" "$volume"
  fi
}

clock() {
	printf "^c$black^ ^b$darkblue^ 󱑆 "
	printf "^c$black^^b$blue^ $(date '+%a %b %e %H:%M')  "
}

while true; do

  [ $interval = 0 ] || [ $(($interval % 3600)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name "$updates $(brightness) $(volume) $(cpu) $(mem)  $(battery) $(clock)"
done
