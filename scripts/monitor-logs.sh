#!/bin/bash

# Monitor CloudWatch logs for all components
# Usage: ./scripts/monitor-logs.sh [environment] [component]
# Components: lambda1, lambda2, lambda3, stepfunctions, all (default)

set -e

# Configuration
ENVIRONMENT=${1:-development}
COMPONENT=${2:-all}
APP_NAME=${APP_NAME:-my-serverless-app}

echo "Monitoring CloudWatch logs..."
echo "Environment: $ENVIRONMENT"
echo "Component: $COMPONENT"
echo "App Name: $APP_NAME"

# Function to tail logs for a specific log group
tail_logs() {
    local log_group=$1
    local component_name=$2
    
    echo "\n=== Monitoring $component_name logs ==="
    echo "Log Group: $log_group"
    echo "Press Ctrl+C to stop monitoring"
    echo "----------------------------------------"
    
    # Check if log group exists
    if ! aws logs describe-log-groups --log-group-name-prefix "$log_group" --query 'logGroups[0].logGroupName' --output text >/dev/null 2>&1; then
        echo "Warning: Log group $log_group not found. Make sure the application is deployed and has been executed."
        return 1
    fi
    
    # Tail the logs
    aws logs tail "$log_group" \
        --follow \
        --format short \
        --filter-pattern "" \
        --since 1h
}

# Function to show recent logs for a specific log group
show_recent_logs() {
    local log_group=$1
    local component_name=$2
    
    echo "\n=== Recent $component_name logs (last 10 minutes) ==="
    echo "Log Group: $log_group"
    echo "----------------------------------------"
    
    # Check if log group exists
    if ! aws logs describe-log-groups --log-group-name-prefix "$log_group" --query 'logGroups[0].logGroupName' --output text >/dev/null 2>&1; then
        echo "Warning: Log group $log_group not found."
        return 1
    fi
    
    # Show recent logs
    aws logs tail "$log_group" \
        --format short \
        --since 10m || echo "No recent logs found for $component_name"
}

# Define log groups
LAMBDA1_LOG_GROUP="/aws/lambda/$APP_NAME-lambda1"
LAMBDA2_LOG_GROUP="/aws/lambda/$APP_NAME-lambda2"
LAMBDA3_LOG_GROUP="/aws/lambda/$APP_NAME-lambda3"
STEPFUNCTIONS_LOG_GROUP="/aws/stepfunctions/$APP_NAME-workflow"

# Handle different monitoring options
case $COMPONENT in
    "lambda1")
        tail_logs "$LAMBDA1_LOG_GROUP" "Lambda 1"
        ;;
    "lambda2")
        tail_logs "$LAMBDA2_LOG_GROUP" "Lambda 2"
        ;;
    "lambda3")
        tail_logs "$LAMBDA3_LOG_GROUP" "Lambda 3"
        ;;
    "stepfunctions")
        tail_logs "$STEPFUNCTIONS_LOG_GROUP" "Step Functions"
        ;;
    "recent")
        echo "Showing recent logs from all components..."
        show_recent_logs "$LAMBDA1_LOG_GROUP" "Lambda 1"
        show_recent_logs "$LAMBDA2_LOG_GROUP" "Lambda 2"
        show_recent_logs "$LAMBDA3_LOG_GROUP" "Lambda 3"
        show_recent_logs "$STEPFUNCTIONS_LOG_GROUP" "Step Functions"
        ;;
    "all")
        echo "Available log groups:"
        echo "1. $LAMBDA1_LOG_GROUP"
        echo "2. $LAMBDA2_LOG_GROUP"
        echo "3. $LAMBDA3_LOG_GROUP"
        echo "4. $STEPFUNCTIONS_LOG_GROUP"
        echo ""
        echo "Select a component to monitor:"
        echo "1) lambda1      - Monitor Lambda 1 logs"
        echo "2) lambda2      - Monitor Lambda 2 logs"
        echo "3) lambda3      - Monitor Lambda 3 logs"
        echo "4) stepfunctions - Monitor Step Functions logs"
        echo "5) recent       - Show recent logs from all components"
        echo "6) quit         - Exit"
        echo ""
        
        while true; do
            read -p "Choose an option (1-6): " choice
            case $choice in
                1) tail_logs "$LAMBDA1_LOG_GROUP" "Lambda 1"; break ;;
                2) tail_logs "$LAMBDA2_LOG_GROUP" "Lambda 2"; break ;;
                3) tail_logs "$LAMBDA3_LOG_GROUP" "Lambda 3"; break ;;
                4) tail_logs "$STEPFUNCTIONS_LOG_GROUP" "Step Functions"; break ;;
                5) show_recent_logs "$LAMBDA1_LOG_GROUP" "Lambda 1"
                   show_recent_logs "$LAMBDA2_LOG_GROUP" "Lambda 2"
                   show_recent_logs "$LAMBDA3_LOG_GROUP" "Lambda 3"
                   show_recent_logs "$STEPFUNCTIONS_LOG_GROUP" "Step Functions"
                   break ;;
                6) echo "Goodbye!"; exit 0 ;;
                *) echo "Invalid option. Please choose 1-6." ;;
            esac
        done
        ;;
    *)
        echo "Unknown component: $COMPONENT"
        echo "Available components: lambda1, lambda2, lambda3, stepfunctions, recent, all"
        exit 1
        ;;
esac

echo "\nLog monitoring completed."