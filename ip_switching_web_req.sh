#!/bin/bash

change_server() {
  local COUNTRY=$1
  
  mullvad disconnect
  sleep 2
  
  if [ -z "$COUNTRY" ]; then
    COUNTRIES=$(mullvad relay list | grep -v "relay" | awk '{print $1}' | sort -u)
    COUNTRY=$(echo "$COUNTRIES" | shuf -n 1)
  fi
  
  CITIES=$(mullvad relay list | grep "$COUNTRY" | awk '{print $3}' | sort -u)
  
  if [ -z "$CITIES" ]; then
    echo "No cities found for country $COUNTRY, trying another country"
    change_server
    return
  fi
  
  CITY=$(echo "$CITIES" | shuf -n 1)
  
  echo "Connecting to $COUNTRY-$CITY"
  mullvad relay set location "$COUNTRY" "$CITY"
  mullvad connect
  sleep 5
  
  echo "New IP: $(curl -s https://api.ipify.org)"
}

for i in {1..50}; do
  echo "Requests $i of 100"

  change_server
  
  # change this
  json_data="{}"
  echo "$json_data"

  response=$(
    curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$json_data" \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)" \
    "http://www.domain.local/post"

  )

    echo "Response: $response"
    echo "----------------------"
  sleep 1

done
