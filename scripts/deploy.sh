#!/bin/bash

# Deploy AWS Step Functions and Lambda functions
# Usage: ./scripts/deploy.sh

set -e

# Configuration (change these if needed)
APP_NAME="my-serverless-app"
AWS_REGION="us-east-1"
ENVIRONMENT="production"

echo "🚀 Starting deployment..."
echo "App Name: $APP_NAME"
echo "AWS Region: $AWS_REGION"
echo "Environment: $ENVIRONMENT"

# Load environment variables from .env if it exists
if [ -f ".env" ]; then
    echo "📄 Loading environment variables from .env file..."
    source .env
fi

# Check required environment variables
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY environment variable is required"
    echo "Please set it in your .env file or environment"
    exit 1
fi

if [ -z "$GOOGLE_DRIVE_FOLDER_ID" ]; then
    echo "❌ Error: GOOGLE_DRIVE_FOLDER_ID environment variable is required" 
    echo "Please set it in your .env file or environment"
    exit 1
fi

# Create dist directory for Lambda packages
echo ""
echo "📦 Building Lambda packages..."
mkdir -p dist

# Build Lambda 1 package
echo "Building Lambda 1..."
cd src/lambda1
pip install -r requirements.txt -t ./package
cp handler.py ./package/
cd package
zip -r ../../../dist/lambda1.zip .
cd ../../..

# Build Lambda 2 package  
echo "Building Lambda 2..."
cd src/lambda2
pip install -r requirements.txt -t ./package
cp handler.py ./package/
cd package
zip -r ../../../dist/lambda2.zip .
cd ../../..

# Build Lambda 3 package
echo "Building Lambda 3..."
cd src/lambda3
pip install -r requirements.txt -t ./package
cp handler.py ./package/
cd package
zip -r ../../../dist/lambda3.zip .
cd ../../..

echo "✅ Lambda packages built successfully"

# Navigate to terraform directory
cd terraform

# Initialize Terraform (no backend - uses local state)
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo ""
echo "✅ Validating Terraform configuration..."
terraform validate

# Format Terraform files
echo ""
echo "🎨 Formatting Terraform files..."
terraform fmt

# Plan deployment
echo ""
echo "📋 Creating deployment plan..."
terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="openai_api_key=$OPENAI_API_KEY" \
    -var="google_drive_folder_id=$GOOGLE_DRIVE_FOLDER_ID" \
    -var="eventbridge_enabled=true" \
    -out=tfplan

# Ask for confirmation
echo ""
echo "🤔 Ready to deploy. This will create AWS resources that may incur costs."
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 0
fi

# Apply deployment
echo ""
echo "🚀 Deploying infrastructure..."
terraform apply -auto-approve tfplan

# Show outputs
echo ""
echo "📊 Deployment outputs:"
terraform output

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "💡 What's deployed:"
echo "   - 3 Lambda functions (lambda1, lambda2, lambda3)"
echo "   - Step Functions state machine"
echo "   - IAM roles and policies"
echo "   - EventBridge rules (if enabled)"
echo ""
echo "🧪 To test your deployment:"
echo "   1. Check AWS Console > Step Functions"
echo "   2. Start a new execution with test input: {\"test\": true}"
echo "   3. Monitor the execution in the console"

# Save deployment info for reference
cd ..
cat > deployment-info.json << EOF
{
  "environment": "$ENVIRONMENT",
  "app_name": "$APP_NAME", 
  "aws_region": "$AWS_REGION",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo ""
echo "📝 Deployment info saved to deployment-info.json"