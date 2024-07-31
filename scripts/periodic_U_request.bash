#!/bin/bash
api_url="${AI_GATEWAY_URL:-https://dream-gateway.livepeer.cloud}"
bearer_token="${AI_BEARER_TOKEN:-}"

# Get script arguments or use default values.
batch_sleep_duration=${1:-1800}             # Pause for 30 minutes by default
request_max_random_sleep_duration=${2:-60}  # Sleep for a random time between 0 and 60 seconds by default
batch_size=${2:-2}                          # Send 2 requests per batch by default

# Request T2I job.
send_request() {
    echo -n "$(date '+%Y-%m-%d %H:%M:%S') - "
    curl -X POST ${api_url}/upscale \
    -H "Authorization: Bearer ${bearer_token}" \
    -F model_id="stabilityai/stable-diffusion-x4-upscaler" \
    -F image=@example_files/cool-cat-low-res.png \
    -F prompt="put the cat in the original image on the beach" &
}

while true; do
    # Periodically send requests in batches.
    for ((i=1; i<=batch_size; i++)); do
        send_request
        if [ "$request_max_random_sleep_duration" -ne 0 ]; then
            sleep $((RANDOM % request_max_random_sleep_duration + 1))
        fi
    done
    sleep ${batch_sleep_duration}
done
