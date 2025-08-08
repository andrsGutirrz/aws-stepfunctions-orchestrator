#!/bin/bash

# Build and push Docker images to ECR
# Usage: ./scripts/build-and-push.sh [environment] [tag]

set -e

# Configuration
ENVIRONMENT=${1:-development}
IMAGE_TAG=${2:-latest}
APP_NAME=${APP_NAME:-my-serverless-app}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Building and pushing Docker images..."
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "App Name: $APP_NAME"
echo "AWS Region: $AWS_REGION"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: Unable to get AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Function to build and push a single lambda
build_and_push_lambda() {
    local lambda_name=$1
    local lambda_dir="src/$lambda_name"
    local repository_name="$APP_NAME-$lambda_name"
    local repository_uri="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$repository_name"
    
    echo "\n=== Building $lambda_name ==="
    
    # Create ECR repository if it doesn't exist
    aws ecr describe-repositories --repository-names $repository_name --region $AWS_REGION > /dev/null 2>&1 || {
        echo "Creating ECR repository: $repository_name"
        aws ecr create-repository --repository-name $repository_name --region $AWS_REGION
    }
    
    # Build Docker image
    echo "Building Docker image for $lambda_name..."
    docker build -t $repository_name:$IMAGE_TAG $lambda_dir
    
    # Tag for ECR
    docker tag $repository_name:$IMAGE_TAG $repository_uri:$IMAGE_TAG
    docker tag $repository_name:$IMAGE_TAG $repository_uri:latest
    
    # Push to ECR
    echo "Pushing $lambda_name to ECR..."
    docker push $repository_uri:$IMAGE_TAG
    docker push $repository_uri:latest
    
    echo "✓ Successfully built and pushed $lambda_name"
}

# Build and push all lambda functions
build_and_push_lambda "lambda1"
build_and_push_lambda "lambda2"
build_and_push_lambda "lambda3"

echo "\n🎉 All Docker images built and pushed successfully!"
echo "\nNext steps:"
echo "1. Update your Terraform variables if needed:"
echo "   terraform/terraform.tfvars"
echo "2. Deploy infrastructure:"
echo "   ./scripts/deploy.sh $ENVIRONMENT $IMAGE_TAG"
echo "3. Test the deployment:"
echo "   ./scripts/test-workflow.sh $ENVIRONMENT"