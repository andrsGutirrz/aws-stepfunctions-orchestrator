#!/bin/bash

# Test the Step Functions workflow
# Usage: ./scripts/test-workflow.sh [environment]

set -e

# Configuration
ENVIRONMENT=${1:-development}
APP_NAME=${APP_NAME:-my-serverless-app}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Testing Step Functions workflow..."
echo "Environment: $ENVIRONMENT"
echo "App Name: $APP_NAME"
echo "AWS Region: $AWS_REGION"

# Get the state machine ARN from terraform output or deployment info
if [ -f "deployment-info.json" ]; then
    STATE_MACHINE_ARN=$(cat deployment-info.json | jq -r '.terraform_outputs.step_functions_state_machine_arn.value')
elif [ -f "terraform/terraform.tfstate" ]; then
    cd terraform
    STATE_MACHINE_ARN=$(terraform output -raw step_functions_state_machine_arn 2>/dev/null || echo "")
    cd ..
else
    echo "Warning: Could not find deployment info. Trying to discover state machine..."
    STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines --query "stateMachines[?name=='$APP_NAME-workflow'].stateMachineArn | [0]" --output text)
fi

if [ -z "$STATE_MACHINE_ARN" ] || [ "$STATE_MACHINE_ARN" = "null" ] || [ "$STATE_MACHINE_ARN" = "None" ]; then
    echo "Error: Could not find Step Functions state machine ARN"
    echo "Make sure the infrastructure is deployed first: ./scripts/deploy.sh $ENVIRONMENT"
    exit 1
fi

echo "State Machine ARN: $STATE_MACHINE_ARN"

# Create test input
TEST_INPUT=$(cat << EOF
{
  "test": true,
  "trigger_source": "manual_test",
  "test_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "$ENVIRONMENT",
  "message": "Test execution from test-workflow.sh script"
}
EOF
)

echo "\nTest Input:"
echo "$TEST_INPUT" | jq .

# Start execution
echo "\n=== Starting Step Functions Execution ==="
EXECUTION_NAME="test-execution-$(date +%s)"
EXECUTION_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn "$STATE_MACHINE_ARN" \
    --name "$EXECUTION_NAME" \
    --input "$TEST_INPUT" \
    --query 'executionArn' \
    --output text)

echo "Execution ARN: $EXECUTION_ARN"

# Function to get execution status
get_execution_status() {
    aws stepfunctions describe-execution \
        --execution-arn "$EXECUTION_ARN" \
        --query 'status' \
        --output text
}

# Wait for execution to complete
echo "\n=== Monitoring Execution ==="
echo "Waiting for execution to complete..."

START_TIME=$(date +%s)
TIMEOUT=300  # 5 minutes timeout

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "\n⚠️  Execution timeout after ${TIMEOUT} seconds"
        break
    fi
    
    STATUS=$(get_execution_status)
    echo "Status: $STATUS (${ELAPSED}s elapsed)"
    
    if [ "$STATUS" != "RUNNING" ]; then
        break
    fi
    
    sleep 5
done

# Get final execution details
echo "\n=== Execution Results ==="
aws stepfunctions describe-execution \
    --execution-arn "$EXECUTION_ARN" \
    --query '{Status: status, StartDate: startDate, StopDate: stopDate}' \
    --output table

# Get execution history
echo "\n=== Execution History (Last 10 Events) ==="
aws stepfunctions get-execution-history \
    --execution-arn "$EXECUTION_ARN" \
    --max-items 10 \
    --query 'events[].{Type: type, Timestamp: timestamp, Details: executionSucceededEventDetails.output}' \
    --output table

# Get final output if successful
FINAL_STATUS=$(get_execution_status)
if [ "$FINAL_STATUS" = "SUCCEEDED" ]; then
    echo "\n=== Final Output ==="
    aws stepfunctions get-execution-history \
        --execution-arn "$EXECUTION_ARN" \
        --query 'events[?type==`ExecutionSucceeded`].executionSucceededEventDetails.output' \
        --output text | jq -r . | jq .
    
    echo "\n✓ 🎉 Workflow execution completed successfully!"
    echo "\nWhat happened:"
    echo "1. Lambda 1 printed 'Hello' and passed data to Lambda 2"
    echo "2. Lambda 2 printed 'World' and combined with previous message"
    echo "3. Lambda 3 printed ':)' and returned the final result: 'Hello World :)'"
elif [ "$FINAL_STATUS" = "FAILED" ]; then
    echo "\n❌ Workflow execution failed!"
    
    # Get error details
    echo "\n=== Error Details ==="
    aws stepfunctions get-execution-history \
        --execution-arn "$EXECUTION_ARN" \
        --query 'events[?type==`ExecutionFailed`].executionFailedEventDetails' \
        --output json | jq .
else
    echo "\n⚠️  Workflow execution did not complete normally. Status: $FINAL_STATUS"
fi

echo "\n=== CloudWatch Logs ==="
echo "You can view detailed logs in CloudWatch:"
echo "- Lambda 1: /aws/lambda/$APP_NAME-lambda1"
echo "- Lambda 2: /aws/lambda/$APP_NAME-lambda2"
echo "- Lambda 3: /aws/lambda/$APP_NAME-lambda3"
echo "- Step Functions: /aws/stepfunctions/$APP_NAME-workflow"
echo "\nOr use: ./scripts/monitor-logs.sh $ENVIRONMENT"