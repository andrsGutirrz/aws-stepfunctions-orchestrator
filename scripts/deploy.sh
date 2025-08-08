#!/bin/bash

# Deploy infrastructure using Terraform
# Usage: ./scripts/deploy.sh [environment] [image_tag]

set -e

# Configuration
ENVIRONMENT=${1:-development}
IMAGE_TAG=${2:-latest}
APP_NAME=${APP_NAME:-my-serverless-app}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Deploying infrastructure..."
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "App Name: $APP_NAME"
echo "AWS Region: $AWS_REGION"

# Check if .env file exists for local development
if [ -f ".env" ] && [ "$ENVIRONMENT" = "development" ]; then
    echo "Loading environment variables from .env file..."
    source .env
fi

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo "\n=== Terraform Init ==="
terraform init

# Validate Terraform configuration
echo "\n=== Terraform Validate ==="
terraform validate

# Format check
echo "\n=== Terraform Format Check ==="
terraform fmt -check -diff

# Plan deployment
echo "\n=== Terraform Plan ==="
terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="image_tag=$IMAGE_TAG" \
    -var="app_name=$APP_NAME" \
    -var="aws_region=$AWS_REGION" \
    -var="openai_api_key=${OPENAI_API_KEY:-sk-placeholder-key}" \
    -var="google_drive_folder_id=${GOOGLE_DRIVE_FOLDER_ID:-placeholder-folder-id}" \
    -var="eventbridge_enabled=${EVENTBRIDGE_ENABLED:-false}" \
    -out=tfplan

# Ask for confirmation if not in CI/CD environment
if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ]; then
    echo "\n=== Deployment Confirmation ==="
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Apply deployment
echo "\n=== Terraform Apply ==="
terraform apply -auto-approve tfplan

# Show outputs
echo "\n=== Deployment Outputs ==="
terraform output

echo "\n🎉 Deployment completed successfully!"
echo "\nNext steps:"
echo "1. Test individual Lambda functions:"
echo "   aws lambda invoke --function-name $APP_NAME-lambda1 --payload '{}' response.json"
echo "2. Test the complete workflow:"
echo "   ./scripts/test-workflow.sh $ENVIRONMENT"
echo "3. Monitor logs:"
echo "   ./scripts/monitor-logs.sh $ENVIRONMENT"

# Save deployment info
cat > ../deployment-info.json << EOF
{
  "environment": "$ENVIRONMENT",
  "image_tag": "$IMAGE_TAG",
  "app_name": "$APP_NAME",
  "aws_region": "$AWS_REGION",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "terraform_outputs": $(terraform output -json)
}
EOF

echo "Deployment information saved to deployment-info.json"