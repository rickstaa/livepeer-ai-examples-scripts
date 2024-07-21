#!/bin/bash
api_url="${AI_GATEWAY_URL:-https://dream-gateway.livepeer.cloud}"
bearer_token="${AI_BEARER_TOKEN:-}"

# Get script arguments or use default values.
batch_sleep_duration=${1:-1800}             # Pause for 30 minutes by default
request_max_random_sleep_duration=${2:-60}  # Sleep for a random time between 0 and 60 seconds by default
batch_size=${3:-3}                          # Send 3 requests per batch by default

# Request T2I job.
send_request() {
    curl -X POST ${api_url}/text-to-image \
    -H "Authorization: Bearer ${bearer_token}" \
    -d '{
    "model_id": "SG161222/RealVisXL_V4.0_Lightning",
    "prompt": "a small white kitten on a blue hammock and a palm tree at an abstract ethereal semi - transparent sunny beach among rainbow light impressive skies",
    "negative_prompt": "",
    "guidance_scale": 7,
    "width": 1024,
    "height": 1024,
    "num_inference_steps": 6,
    "num_images_per_prompt": 3
    }'
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
