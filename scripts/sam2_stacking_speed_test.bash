#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 port1 [port2 ... portN]"
    exit 1
fi

ports=("$@")
num_ports=${#ports[@]}
num_requests=$((num_ports * 4))
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
    echo "Timing for $num_services parallel request(s) with 4 requests per port..."
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
    time_per_request=$((elapsed_time_ms / num_requests))
    echo "Elapsed time for $num_services parallel request(s) with 4 requests per port: $elapsed_time_ms ms (Total), $time_per_request ms (Per request)"
}

# Measure the time for sending requests to 1, 2, ..., num_ports services.
echo "Starting SAM2 stacking speed test..."
for num_services in $(seq 1 $num_ports); do
    measure_time $num_services
done

# Calculate the mean time added for each additional request.
total_added_time=0
for ((i=2; i<=num_ports; i++)); do
    added_time=$((times[i] - times[i-1]))
    total_added_time=$((total_added_time + added_time))
done
mean_added_time=$((total_added_time / (num_ports - 1)))

echo "Mean time added for each additional request: $mean_added_time ms"

# Calculate the percentage increase in total time for each additional request.
base_time=${times[1]}
for ((i=2; i<=num_ports; i++)); do
    percentage_increase=$(echo "scale=2; (${times[i]} - $base_time) * 100 / $base_time" | bc)
    echo "Percentage increase for $i parallel request(s) compared to 1 request: $percentage_increase%"
done

echo "SAM2 stacking speed test complete."
echo "NOTICE: Please keep the request time increase below 25% for optimal performance."
