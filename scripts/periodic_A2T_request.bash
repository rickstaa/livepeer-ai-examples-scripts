#!/bin/bash
api_url="${AI_GATEWAY_URL:-https://dream-gateway.livepeer.cloud}"
bearer_token="${AI_BEARER_TOKEN:-}"

# Get script arguments or use default values.
batch_sleep_duration=${1:-1800}             # Pause for 30 minutes by default
request_max_random_sleep_duration=${2:-60}  # Sleep for a random time between 0 and 60 seconds by default
batch_size=${3:-3}                          # Send 3 requests per batch by default

# Request T2I job.
send_request() {
    echo -n "$(date '+%Y-%m-%d %H:%M:%S') - "
    curl -X POST ${api_url}/audio-to-text \
    -H "Authorization: Bearer ${bearer_token}" \
    -F model_id=openai/whisper-large-v3 \
    -F audio=@example_files/test_audio.flac
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
