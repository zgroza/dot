#!/bin/zsh

# This script uses pactl and Rofi to display a menu of audio sinks or sources
# and set the chosen one as default.

# Check for the correct number of arguments
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 [sink|source]"
    exit 1
fi

type="$1"

# Validate the argument
if [[ "$type" != "sink" && "$type" != "source" ]]; then
    echo "Invalid argument: '$type'. Please use 'sink' or 'source'."
    echo "Usage: $0 [sink|source]"
    exit 1
fi

# Determine the pactl command and Rofi prompt based on the type
if [[ "$type" == "sink" ]]; then
    pactl_command="pactl list sinks"
    set_default_command="pactl set-default-sink"
else
    pactl_command="pactl list sources"
    set_default_command="pactl set-default-source"
fi

# Get the list of sinks or sources with their description and name
# Filter out "monitor" entries.
device_info=$(eval "$pactl_command" | awk '
/^Sink #/ || /^Source #/ {
    if (name != "" && description != "") {
        # Filter out "monitor" entries
        if (description !~ /monitor/ && name !~ /monitor/) {
            print description "::" name
        }
    }
    name = ""
    description = ""
}
/Description:/ {
    description = substr($0, index($0, $2))
}
/Name:/ {
    name = substr($0, index($0, $2))
}
END {
    if (name != "" && description != "") {
        # Filter out "monitor" entries for the last block
        if (description !~ /monitor/ && name !~ /monitor/) {
            print description "::" name
        }
    }
}')

# Check if any devices were found after filtering
if [[ -z "$device_info" ]]; then
    echo "No non-monitor audio $type's found."
    exit 1
fi

# Use Rofi to display the descriptions and let the user choose
chosen_description_name=$(echo "$device_info" | awk -F'::' '{print $1}' | rofi -dmenu)

# Check if the user made a selection
if [[ -z "$chosen_description_name" ]]; then
    echo "No $type selected."
    exit 0
fi

# Find the corresponding device name for the chosen description
chosen_device_name=$(echo "$device_info" | awk -F'::' -v desc="$chosen_description_name" '$1 == desc {print $2; exit}')

# Set the chosen device as default
if [[ -n "$chosen_device_name" ]]; then
    eval "$set_default_command" "$chosen_device_name"
    echo "Default audio $type set to: **$chosen_description_name** ($chosen_device_name)"
else
    echo "Error: Could not find $type name for description '**$chosen_description_name**'."
    exit 1
fi
