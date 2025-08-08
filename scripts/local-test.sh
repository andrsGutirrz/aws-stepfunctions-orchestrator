#!/bin/bash

# Local testing script using Docker
# Usage: ./scripts/local-test.sh [lambda] [test_data]
# Lambda options: lambda1, lambda2, lambda3, all

set -e

# Configuration
LAMBDA=${1:-all}
TEST_DATA=${2:-'{"test": true}'}
APP_NAME=${APP_NAME:-my-serverless-app}

echo "Local testing with Docker..."
echo "Lambda: $LAMBDA"
echo "Test Data: $TEST_DATA"

# Load environment variables from .env if it exists
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
    export LOCAL_DEVELOPMENT=true
else
    echo "Warning: .env file not found. Create one from .env.example for local testing."
    export LOCAL_DEVELOPMENT=true
    export OPENAI_API_KEY="sk-test-key"
    export GOOGLE_DRIVE_FOLDER_ID="test-folder-id"
fi

# Function to test a single lambda
test_lambda() {
    local lambda_name=$1
    local input_data=$2
    local lambda_dir="src/$lambda_name"
    
    if [ ! -d "$lambda_dir" ]; then
        echo "Error: Lambda directory $lambda_dir not found"
        return 1
    fi
    
    echo "\n=== Testing $lambda_name ==="
    echo "Input: $input_data"
    
    # Build the image
    echo "Building Docker image for $lambda_name..."
    docker build -t "$APP_NAME-$lambda_name:test" "$lambda_dir"
    
    # Create a temporary file for the test event
    local temp_event="/tmp/test_event_$lambda_name.json"
    echo "$input_data" > "$temp_event"
    
    # Run the container with AWS Lambda Runtime Interface Emulator
    echo "Running $lambda_name locally..."
    
    # Start container in background
    local container_id=$(docker run -d \
        -p 9000:8080 \
        -e LOCAL_DEVELOPMENT="$LOCAL_DEVELOPMENT" \
        -e OPENAI_API_KEY="$OPENAI_API_KEY" \
        -e GOOGLE_DRIVE_FOLDER_ID="$GOOGLE_DRIVE_FOLDER_ID" \
        "$APP_NAME-$lambda_name:test")
    
    # Wait for container to be ready
    echo "Waiting for container to be ready..."
    sleep 3
    
    # Test the function
    local response=$(curl -s -X POST \
        "http://localhost:9000/2015-03-31/functions/function/invocations" \
        -d "$input_data" 2>/dev/null || echo '{"error": "Failed to invoke function"}')
    
    echo "Response:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
    
    # Get container logs
    echo "\nContainer logs:"
    docker logs "$container_id" 2>&1 | tail -20
    
    # Clean up
    docker stop "$container_id" >/dev/null 2>&1
    docker rm "$container_id" >/dev/null 2>&1
    rm -f "$temp_event"
    
    echo "✓ Test completed for $lambda_name"
}

# Function to test the workflow locally (sequential execution)
test_workflow() {
    echo "\n=== Testing Complete Workflow Locally ==="
    
    # Test data
    local lambda1_input='{"test": true, "trigger_source": "local_test"}'
    
    echo "Step 1: Testing Lambda 1..."
    # For local testing, we'll simulate the workflow step by step
    
    # Build all images first
    echo "Building all Docker images..."
    docker build -t "$APP_NAME-lambda1:test" "src/lambda1"
    docker build -t "$APP_NAME-lambda2:test" "src/lambda2"
    docker build -t "$APP_NAME-lambda3:test" "src/lambda3"
    
    # Test Lambda 1
    echo "\n--- Lambda 1 Test ---"
    local container1_id=$(docker run -d \
        -p 9001:8080 \
        -e LOCAL_DEVELOPMENT="$LOCAL_DEVELOPMENT" \
        -e OPENAI_API_KEY="$OPENAI_API_KEY" \
        -e GOOGLE_DRIVE_FOLDER_ID="$GOOGLE_DRIVE_FOLDER_ID" \
        "$APP_NAME-lambda1:test")
    
    sleep 3
    local lambda1_response=$(curl -s -X POST \
        "http://localhost:9001/2015-03-31/functions/function/invocations" \
        -d "$lambda1_input")
    
    echo "Lambda 1 Response:"
    echo "$lambda1_response" | jq .
    
    docker stop "$container1_id" >/dev/null 2>&1
    docker rm "$container1_id" >/dev/null 2>&1
    
    # Extract data for Lambda 2
    local lambda2_input=$(echo "$lambda1_response" | jq '.data')
    
    # Test Lambda 2
    echo "\n--- Lambda 2 Test ---"
    local container2_id=$(docker run -d \
        -p 9002:8080 \
        -e LOCAL_DEVELOPMENT="$LOCAL_DEVELOPMENT" \
        -e OPENAI_API_KEY="$OPENAI_API_KEY" \
        -e GOOGLE_DRIVE_FOLDER_ID="$GOOGLE_DRIVE_FOLDER_ID" \
        "$APP_NAME-lambda2:test")
    
    sleep 3
    local lambda2_response=$(curl -s -X POST \
        "http://localhost:9002/2015-03-31/functions/function/invocations" \
        -d "{\"data\": $lambda2_input}")
    
    echo "Lambda 2 Response:"
    echo "$lambda2_response" | jq .
    
    docker stop "$container2_id" >/dev/null 2>&1
    docker rm "$container2_id" >/dev/null 2>&1
    
    # Extract data for Lambda 3
    local lambda3_input=$(echo "$lambda2_response" | jq '.data')
    
    # Test Lambda 3
    echo "\n--- Lambda 3 Test ---"
    local container3_id=$(docker run -d \
        -p 9003:8080 \
        -e LOCAL_DEVELOPMENT="$LOCAL_DEVELOPMENT" \
        -e OPENAI_API_KEY="$OPENAI_API_KEY" \
        -e GOOGLE_DRIVE_FOLDER_ID="$GOOGLE_DRIVE_FOLDER_ID" \
        "$APP_NAME-lambda3:test")
    
    sleep 3
    local lambda3_response=$(curl -s -X POST \
        "http://localhost:9003/2015-03-31/functions/function/invocations" \
        -d "{\"data\": $lambda3_input}")
    
    echo "Lambda 3 Response:"
    echo "$lambda3_response" | jq .
    
    docker stop "$container3_id" >/dev/null 2>&1
    docker rm "$container3_id" >/dev/null 2>&1
    
    echo "\n🎉 Workflow test completed!"
    echo "Final result should show: 'Hello World :)'"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq is not installed. JSON output may not be formatted nicely."
fi

# Main logic
case $LAMBDA in
    "lambda1")
        test_lambda "lambda1" "$TEST_DATA"
        ;;
    "lambda2")
        # For lambda2, we need to simulate data from lambda1
        lambda2_input='{"data": {"message": "Hello", "lambda_name": "lambda1"}, "test": true}'
        test_lambda "lambda2" "$lambda2_input"
        ;;
    "lambda3")
        # For lambda3, we need to simulate data from lambda2
        lambda3_input='{"data": {"combined_message": "Hello World", "lambda_name": "lambda2"}, "test": true}'
        test_lambda "lambda3" "$lambda3_input"
        ;;
    "workflow")
        test_workflow
        ;;
    "all")
        echo "Choose testing option:"
        echo "1) Test individual Lambda functions"
        echo "2) Test complete workflow simulation"
        echo "3) Test specific Lambda with custom data"
        echo ""
        read -p "Choose option (1-3): " choice
        
        case $choice in
            1)
                test_lambda "lambda1" '{"test": true}'
                test_lambda "lambda2" '{"data": {"message": "Hello"}, "test": true}'
                test_lambda "lambda3" '{"data": {"combined_message": "Hello World"}, "test": true}'
                ;;
            2)
                test_workflow
                ;;
            3)
                echo "Available Lambdas: lambda1, lambda2, lambda3"
                read -p "Enter Lambda name: " lambda_choice
                read -p "Enter test data (JSON): " data_choice
                test_lambda "$lambda_choice" "$data_choice"
                ;;
            *)
                echo "Invalid option"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown lambda: $LAMBDA"
        echo "Available options: lambda1, lambda2, lambda3, workflow, all"
        exit 1
        ;;
esac

echo "\nLocal testing completed!"
echo "\nNext steps:"
echo "1. If tests pass, build and push to ECR: ./scripts/build-and-push.sh"
echo "2. Deploy to AWS: ./scripts/deploy.sh"
echo "3. Test on AWS: ./scripts/test-workflow.sh"