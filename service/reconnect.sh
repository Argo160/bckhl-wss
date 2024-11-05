#!/bin/bash

# Get the service name from the argument passed to this script
service_name="$1"

# Check if a service name was provided
if [[ -z "$service_name" ]]; then
    echo "Error: No service name provided."
    exit 1
fi

# Stop, start, and restart the specified service
systemctl stop "${service_name}.service"
systemctl start "${service_name}.service"
systemctl restart "${service_name}.service"
