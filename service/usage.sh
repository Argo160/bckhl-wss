#!/bin/bash

log_dir="/root/"  # Directory containing your log files

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
    for log_file in "$log_dir"/*.json; do
        if [[ -f $log_file ]]; then
            service_name=$(basename "$log_file" .json)  # Get the service name from the filename
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
                python3 /root/py-script.py "$status_message"  # Send the status to Telegram

                # Call send_message.py if the service is disconnected and button not already sent
                if [[ "$current_status" == "DISCONNECTED ❌" && -z "${button_sent[$service_name]}" ]]; then
                    python3 /root/send_status.py "$service_name"  # Send the message with the button
                    echo "$service_name"
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
        sleep 60  # Checks every 60 seconds
    done
}

# Start checking
python3 button_listener.py &
check
