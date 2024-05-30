#!/usr/bin/bash
# toolReportTime.sh

reportTime() {
    command_to_run=$1
    output_file=$2
    file=$3
    iterations=1

    # Create a temporary file to capture time output
    temp_time_file=$(mktemp)

    # Create the loop command to run the original command multiple times
    loop_command="for i in \$(seq 1 $iterations); do $command_to_run > $output_file; done"

    # Run the command and capture time data
    { time bash -c "$loop_command" ; } 2> "$temp_time_file"

    # Read the timing data from the temporary file
    timing_data=$(<"$temp_time_file")

    # Delete the temporary file
    rm "$temp_time_file"

    # Extract Real, User, and System time from the timing data
    real_time=$(echo "$timing_data" | awk '/real/ {print $2}')
    user_time=$(echo "$timing_data" | awk '/user/ {print $2}')
    sys_time=$(echo "$timing_data" | awk '/sys/ {print $2}')

    # Convert times to seconds (they are in the format YmX.XXXs)
    real_time=$(echo "$real_time" | awk -F 'm|s' '{print $1*60 + $2}')
    user_time=$(echo "$user_time" | awk -F 'm|s' '{print $1*60 + $2}')
    sys_time=$(echo "$sys_time" | awk -F 'm|s' '{print $1*60 + $2}')

    # Calculate the average times
    avg_real_time=$(printf "%.4f" "$(echo "$real_time / $iterations" | tr -d '\000' | bc -l)")
    avg_user_time=$(printf "%.4f" "$(echo "$user_time / $iterations" | tr -d '\000' | bc -l)")
    avg_sys_time=$(printf "%.4f" "$(echo "$sys_time / $iterations" | tr -d '\000' | bc -l)")

    # Return the filename, average real time, and average sys time as a comma-separated string
    echo "$file,$avg_real_time,$avg_user_time,$avg_sys_time"
}
