#!/bin/bash

SP_DEST="org.mpris.MediaPlayer2.spotify"
SP_PATH="/org/mpris/MediaPlayer2"
SP_MEMB="org.mpris.MediaPlayer2.Player"

sp_metadata() {
 dbus-send \
 --print-reply \
 --dest=$SP_DEST \
 $SP_PATH \
 org.freedesktop.DBus.Properties.Get \
 string:$SP_MEMB \
 string:Metadata
}

make_spotify_status() {
 SPOTIFY_PID="$(pidof -s spotify)"
 if [[ "$SPOTIFY_PID" ]]; then
   artist=$(sp_metadata | grep xesam:artist --after 2 \
                        | grep 'variant' --after 1 \
                        | grep string \
                        | cut -d '"' -f 2)
   song=$(sp_metadata | grep xesam:title --after 1 \
                      | grep 'variant' \
                      | cut -d '"' -f 2)
   echo "[Playing: ${artist} - ${song:0:60}] "
 else
   echo ""
 fi
}


filter_empty() {
 if [[ "$1" ]]; then
   echo "$2"
 else
   echo ""
 fi
}

status() {
 # Remaining battery
 if [ -d "/sys/class/power_supply/BAT0" ]; then
   batt=$(cat /sys/class/power_supply/BAT0/capacity)
   batt+="%"
 else
   batt="none"
 fi

 # Battery charging state
 if [ -d "/sys/class/power_supply/BAT0" ]; then
   batt_state=$(cat /sys/class/power_supply/BAT0/status)
   [ "$batt_state" == "Charging" ] && batt_state="*" || batt_state=""
 else
   batt_state=""
 fi

 # Date and time
 datetime=$(date "+%a %d.%m.%Y %H:%M")
    
 # CPU Temp
 temp=$(sensors -u k10temp-pci-00c3 | awk '/temp1/{ print $2 }')

 # Volume
 vol=$(pactl list sinks | awk 'c&&!--c;/State: RUNNING*/{c=8}' \
                        | awk '{ printf("%s/%s/%sdB", $3,$5,$7) }')
    
 # Current keyboard layout
 case "$(xset -q | awk '/LED mask/{ print $10 }')" in
   00000*) KBD="EN" ;;
   00001*) KBD="RU" ;;
   *) KBD="-" ;;
 esac
    
 # Define status items
 items=""
 items+=$(make_spotify_status)
 items+="[CPU Temp: ${temp}] "
 items+=$(filter_empty "$vol" "[Vol: ${vol}] ")
 items+="[Batt: ${batt}${batt_state}] "
 items+="[CKL: ${KBD}] " 
 items+="[${datetime}]"

 xsetroot -name "${items}"
}

while true; do
    status
    sleep 0.5
done

