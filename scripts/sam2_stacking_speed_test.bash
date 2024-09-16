#!/bin/bash
ports=(9000 9001 9002 9003)
num_requests=4
declare -a times

# Function to send a request to a specific port.
send_request() {
    local port=$1
    curl -s -X POST http://0.0.0.0:$port/segment-anything-2 \
        -F model_id="facebook/sam2-hiera-large" \
        -F point_coords="[[120,100],[120,50]]" \
        -F point_labels="[1,0]" \
        -F image=@example_files/cool-cat.png \
        > /dev/null
}

# Function to measure time for sending requests to a given number of services.
measure_time() {
    local num_services=$1
    echo "Timing for $num_services parallel request(s)..."
    start_time=$(date +%s%N)
    for ((i=0; i<num_requests; i++)); do
        for ((j=0; j<num_services; j++)); do
            send_request ${ports[j]} &
        done
        wait
    done
    end_time=$(date +%s%N)
    elapsed_time=$((end_time - start_time))
    elapsed_time_ms=$((elapsed_time / 1000000))
    times[$num_services]=$elapsed_time_ms
    echo "Elapsed time for $num_services parallel request(s): $elapsed_time_ms ms"
}

# Measure the time for sending requests to 1, 2, 3, and 4 services.
echo "Starting SAM2 stacking speed test..."
for num_services in {1..4}; do
    measure_time $num_services
done

# Calculate the mean time added for each additional request.
total_added_time=0
for ((i=2; i<=4; i++)); do
    added_time=$((times[i] - times[i-1]))
    total_added_time=$((total_added_time + added_time))
done
mean_added_time=$((total_added_time / 3))

echo "Mean time added for each additional request: $mean_added_time ms"
