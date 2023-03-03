#!/bin/bash

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
    temp=$(sensors -u k10temp-pci-00c3 | grep -E "temp1_input:" | awk '{print $2}')

    # Volume
    vol=$(pactl list sinks | perl -000ne 'if(/State: RUNNING/){/Volume: front-left: (.+),/; print $1}' | tr -d ' ')
    
	# Current keyboard layout
    case "$(xset -q|grep LED| awk '{ print $10 }')" in
      00000*) KBD="EN" ;;
      00001*) KBD="RU" ;;
      *) KBD="-" ;;
    esac

    # Define status items
    items=""
    items+="[CPU Temp: ${temp}] "
    items+="[Vol: ${vol}] "
    [ "$batt" == "none" ] || items+="[Batt: ${batt}${batt_state}] "
    items+="[CKL: ${KBD}] " 
    items+="[${datetime}]"

    xsetroot -name "${items}"
}

while true; do
    status
    sleep 0.5
done
