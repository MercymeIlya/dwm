#!/bin/bash

declare -r SP_DEST="org.mpris.MediaPlayer2.spotify"
declare -r SP_PATH="/org/mpris/MediaPlayer2"
declare -r SP_MEMB="org.mpris.MediaPlayer2.Player"

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
    declare SPOTIFY_PID="$(pidof -s spotify)"
    if [[ "$SPOTIFY_PID" ]]; then
        declare artist=$(sp_metadata | grep xesam:artist --after 2 \
                            | grep 'variant' --after 1 \
                            | grep string \
                            | cut -d '"' -f 2)
        declare song=$(sp_metadata | grep xesam:title --after 1 \
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

ethernet() {
    declare eno1=$(nmcli d | awk '/^eno/{ print $3 }')
    if [ "$eno1" == "connected" ]; then
        echo "[ETH: Wired] "
    else
        echo ""
    fi
}

wifi() {
    declare wifi_status_raw=$(nmcli g | awk 'NR==2 { print $4 }')
    if [ "$wifi_status_raw" == "enabled" ]; then
        declare wifi_net=$(nmcli d | awk '/^wlp/{ print $4 }')
        echo "[WIFI: ON ${wifi_net}] "
    else
        echo "[WIFI: OFF] "
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
    ny_time=$(TZ='America/New_York' date "+%H:%M")

    # CPU Temp
    temp=$(sensors -u k10temp-pci-00c3 | awk '/temp1/{ print $2 }')

    # Handle volume and mute status
    vol=$(pactl list sinks | awk 'c&&!--c;/State: RUNNING*/{c=8}' | awk '{ printf("%s", $5) }')
    mute_status=$(pactl list sinks | awk 'c&&!--c;/State: RUNNING*/{c=7}' | grep -o "Mute: yes")
    if [[ "$mute_status" == "Mute: yes" ]]; then
        vol="Muted"
    fi

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
    items+=$(wifi)
    items+=$(ethernet)
    items+=$(filter_empty "$vol" "[Vol: ${vol}] ")
    items+="[Batt: ${batt}${batt_state}] "
    items+="[CKL: ${KBD}] "
    items+="[NY ${ny_time}] "
    items+="[${datetime}]"

    xsetroot -name "${items}"
}

while true; do
    status
    sleep 0.5
done

