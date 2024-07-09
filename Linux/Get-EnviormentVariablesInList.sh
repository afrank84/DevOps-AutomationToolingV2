#!/bin/bash
# Save this script as pretty_env.sh and run with: bash pretty_env.sh
env | while IFS= read -r line; do
    var_name=$(echo "$line" | cut -d '=' -f 1)
    var_value=$(echo "$line" | cut -d '=' -f 2-)
    printf "%-30s = %s\n" "$var_name" "$var_value"
done
