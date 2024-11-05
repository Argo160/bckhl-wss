#!/bin/bash

# Load configuration from config.ini
config_file="config.ini"
log_dir=$(awk -F ' = ' '/log_dir/ {print $2}' "$config_file" | xargs)
log_names=$(awk -F ' = ' '/log_name/ {print $2}' "$config_file" | tr -d '[],' | tr -s ' ')
server_name=$(awk -F ' = ' '/server_name/ {print $2}' "$config_file" | xargs)
enable_reconnect=$(awk -F ' = ' '/enable_reconnect/ {print $2}' "$config_file" | xargs)
sleep_time=$(awk -F ' = ' '/sleep_time/ {print $2}' "$config_file" | xargs)  # Read sleep_time

# Define associative arrays to store the initial and current usage for each service
declare -A initial_usage
declare -A service_status
declare -A button_sent  # Track if a button has been sent for each service

# Function to get the usage from a specific log file
get_usage() {
    local log_file=$1
    grep -o '"Usage": [0-9]*' "$log_file" | awk '{sum += $2} END {print sum}'
}

# Function to check each log file and update the service status
check_services() {
    for service_name in $log_names; do
        log_file="${log_dir}/${service_name}.json"
        if [[ -f $log_file ]]; then
            current_usage=$(get_usage "$log_file")

            # Set the initial usage if not already set
            if [[ -z "${initial_usage[$service_name]}" ]]; then
                initial_usage[$service_name]=$current_usage
                continue  # Skip the first check to allow a baseline to be established
            fi

            # Determine the current status for the service by comparing initial and current usage
            if [[ "${initial_usage[$service_name]}" -eq "$current_usage" ]]; then
                current_status="DISCONNECTED ❌"
            else
                current_status="CONNECTED ✅"
            fi

            # Create a message including only the service name and status
            status_message="$service_name: $current_status"

            # Check if the status has changed since the last check
            if [[ "${service_status[$service_name]}" != "$current_status" ]]; then
                # Update the service status
                service_status[$service_name]="$current_status"
                echo "$status_message" >> "$log_dir/${service_name}_monitor_status.log"  # Log the status
                python3 /root/message_modified.py "$status_message" "$server_name"  # Send the status to Telegram

                # Call reconnect.sh if the service is disconnected and enable_reconnect is true
                if [[ "$current_status" == "DISCONNECTED ❌" && -z "${button_sent[$service_name]}" ]]; then
                    if [[ "$enable_reconnect" == "true" ]]; then
                        bash reconnect.sh "$service_name"  # Pass service_name to reconnect.sh
                    fi
                    button_sent[$service_name]=true  # Track that button was sent
                elif [[ "$current_status" == "CONNECTED ✅" && -n "${button_sent[$service_name]}" ]]; then
                    unset button_sent[$service_name]  # Reset button sent if reconnected
                fi
            fi

            # Update the initial usage for the next comparison
            initial_usage[$service_name]=$current_usage
        fi
    done
}

check() {
    while true; do
        check_services  # Check all services
        sleep "$sleep_time"  # Use the configured sleep time
    done
}

# Start checking
check
