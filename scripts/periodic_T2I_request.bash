#!/bin/bash
api_url="${AI_GATEWAY_URL:-https://dream-gateway.livepeer.cloud}"
bearer_token="${AI_BEARER_TOKEN:-}"
model_id="${AI_MODEL_ID:-SG161222/RealVisXL_V4.0_Lightning}"
batch_size="${AI_BATCH_SIZE:-2}"

# Get script arguments or use default values.
batch_sleep_duration=${1:-112.5}            # Pause for N minutes
request_max_random_sleep_duration=${2:-60}  # Sleep for a random time between 0 and N seconds
batch_size=${3:-$batch_size}                # Send N requests per batch 
print_interval=${4:-$batch_size}            # Stats print interval

# Initialize counters.
success_count=0
failure_count=0
total_tries=0

# Request T2I job.
send_request() {
    response=$(curl -s -w "\n%{http_code}" -X POST ${api_url}/text-to-image \
        -H "Authorization: Bearer ${bearer_token}" \
        -d '{
            "model_id": "'${model_id}'",
            "prompt": "a small white kitten on a blue hammock and a palm tree at an abstract ethereal semi - transparent sunny beach among rainbow light impressive skies",
            "negative_prompt": "",
            "guidance_scale": 7,
            "width": 1024,
            "height": 1024,
            "num_inference_steps": 6,
            "num_images_per_prompt": 3
        }'
    )


    # Extract the HTTP status code and print response body.
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $response_body"

    # Check response and print stats.
    if [ "$http_code" -eq 200 ]; then
        success_count=$((success_count + 1))
    else
        failure_count=$((failure_count + 1))
    fi
    total_tries=$((total_tries + 1))
    if [ $((total_tries % print_interval)) -eq 0 ]; then
        success_rate=$(echo "scale=2; $success_count / $total_tries * 100" | bc)
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Total tries: $total_tries, Failures: $failure_count, Success rate: $success_rate%"
    fi
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
