# AWS Serverless Step Functions Orchestrator

A production-ready serverless application that demonstrates AWS Lambda functions orchestrated by Step Functions, with Docker containers and CI/CD deployment using GitHub Actions.

## 🎯 Overview

This application consists of:
- **3 Lambda Functions** (deployed as ZIP files)
  - Lambda 1: Prints "Hello" and passes data to the next lambda
  - Lambda 2: Prints "World" and passes data to the next lambda
  - Lambda 3: Prints ":)" and returns the final result "Hello World :)"
- **Step Functions** workflow for orchestration with error handling and retries
- **EventBridge** triggers to start workflows
- **AWS Secrets Manager** for secure configuration
- **Terraform** infrastructure as code
- **GitHub Actions** for CI/CD deployment
- **Full local development** support with Docker

## 🏗 Architecture

```
EventBridge Rule → Step Functions State Machine → Lambda 1 → Lambda 2 → Lambda 3
                                ↓
                        AWS Secrets Manager
                                ↓
                        CloudWatch Logs & X-Ray
```

## 📦 Repository Structure

```
my-serverless-app/
├── .github/workflows/
│   └── deploy.yml              # CI/CD pipeline
├── src/
│   ├── lambda1/
│   │   ├── handler.py          # Lambda 1 code
│   │   └── requirements.txt    # Lambda 1 dependencies
│   ├── lambda2/            # Same structure as lambda1
│   └── lambda3/            # Same structure as lambda1
├── terraform/
│   ├── main.tf             # Main Terraform config
│   ├── lambda.tf           # Lambda resources
│   ├── step-functions.tf   # Step Functions resources
│   ├── eventbridge.tf      # EventBridge resources
│   ├── secrets.tf          # Secrets Manager resources
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   └── step-functions.json # State machine definition
├── scripts/
│   ├── build-and-push.sh  # Build and push Docker images
│   ├── deploy.sh           # Deploy infrastructure
│   ├── test-workflow.sh    # Test Step Functions workflow
│   ├── monitor-logs.sh     # Monitor CloudWatch logs
│   └── local-test.sh       # Local testing with Docker
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore file
├── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
   ```bash
   aws configure
   ```

2. **Terraform** installed (>= 1.0)
   ```bash
   # macOS
   brew install terraform
   
   # Ubuntu/Debian
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

3. **Python 3.9+** for Lambda function development
   ```bash
   # Verify Python version
   python --version
   ```

4. **jq** for JSON processing (recommended)
   ```bash
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt install jq
   ```

### Local Development Setup

1. **Clone and setup environment**
   ```bash
   git clone <your-repo-url>
   cd aws-stepfunctions-orchestrator
   
   # Copy environment template
   cp .env.example .env
   
   # Edit .env with your actual values
   vim .env
   ```

2. **Test locally**
   ```bash
   # Test individual Lambda functions
   cd src/lambda1 && python handler.py
   cd src/lambda2 && python handler.py
   cd src/lambda3 && python handler.py
   ```

### AWS Deployment

1. **Deploy infrastructure with Terraform**
   ```bash
   ./scripts/deploy.sh development
   ```

3. **Test the deployed workflow**
   ```bash
   ./scripts/test-workflow.sh development
   ```

4. **Monitor logs**
   ```bash
   # Interactive log monitoring
   ./scripts/monitor-logs.sh development
   
   # Monitor specific component
   ./scripts/monitor-logs.sh development lambda1
   ./scripts/monitor-logs.sh development stepfunctions
   ```

## 🔧 Configuration

### Environment Variables

Edit `.env` file for local development:

```bash
# AWS Configuration
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-east-1
ENVIRONMENT=development
APP_NAME=my-serverless-app

# API Keys (for local development only)
OPENAI_API_KEY=sk-your-openai-api-key-here
GOOGLE_DRIVE_FOLDER_ID=your-google-drive-folder-id-here

# Local Development
LOCAL_DEVELOPMENT=true
```

### Terraform Variables

Create `terraform/terraform.tfvars` (optional):

```hcl
app_name    = "my-serverless-app"
environment = "development"
aws_region  = "us-east-1"

# Secrets (use GitHub Secrets for production)
openai_api_key         = "sk-your-key-here"
google_drive_folder_id = "your-folder-id-here"

# EventBridge configuration
eventbridge_enabled  = false  # Set to true for scheduled triggers
eventbridge_schedule = "rate(60 minutes)"
```

## 🏭 CI/CD with GitHub Actions

### Setup GitHub Secrets

Add these secrets to your GitHub repository:

1. **AWS Credentials**
   - `AWS_ACCESS_KEY_ID`: Your AWS access key ID
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

2. **API Keys**
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `GOOGLE_DRIVE_FOLDER_ID`: Your Google Drive folder ID

3. **Terraform State** (if using remote backend)
   - `TERRAFORM_STATE_BUCKET`: S3 bucket for Terraform state

### Deployment Workflow

The GitHub Actions workflow automatically:

1. **Runs Terraform** to deploy/update infrastructure
2. **Tests** the deployed Lambda functions
3. **Tests** the complete Step Functions workflow
4. **Reports** deployment status

Workflow triggers:
- **Push to `main`** → Deploy to production
- **Push to `develop`** → Deploy to staging
- **Pull Requests** → Plan only (no deployment)

## 🧪 Testing

### Local Testing

```bash
# Test individual Lambda functions locally
cd src/lambda1 && python -c "import handler; print(handler.lambda_handler({}, {}))"
cd src/lambda2 && python -c "import handler; print(handler.lambda_handler({}, {}))"
cd src/lambda3 && python -c "import handler; print(handler.lambda_handler({}, {}))"
```

### AWS Testing

```bash
# Test Step Functions workflow
./scripts/test-workflow.sh development

# Test individual Lambda functions
aws lambda invoke \
  --function-name my-serverless-app-lambda1 \
  --payload '{}' \
  response.json

# Test with EventBridge (if enabled)
aws events put-events \
  --entries Source=my-serverless-app.trigger,DetailType="Workflow Trigger",Detail='{}'
```

### Unit Testing (Development)

```bash

```

## 📊 Monitoring and Observability

### CloudWatch Logs

- **Lambda Logs**: `/aws/lambda/my-serverless-app-lambda[1|2|3]`
- **Step Functions Logs**: `/aws/stepfunctions/my-serverless-app-workflow`


## 🔒 Security

### Secrets Management

- **Production**: Uses AWS Secrets Manager
- **Local Development**: Uses `.env` file (never committed)
- **CI/CD**: Uses GitHub Secrets

### IAM Permissions

All IAM roles follow the **principle of least privilege**:

- **Lambda Execution Role**: CloudWatch Logs + Secrets Manager
- **Step Functions Role**: Lambda invocation + CloudWatch Logs
- **EventBridge Role**: Step Functions execution

### Security Best Practices

- ✅ No secrets in code or version control
- ✅ ZIP file deployment with integrity checks
- ✅ CloudWatch logging for audit trails
- ✅ Least privilege IAM policies

## 🚫 Troubleshooting

### Common Issues

1. **Lambda deployment fails**
   ```bash
   # Check function package size
   cd src/lambda1 && zip -r lambda.zip . && ls -lh lambda.zip
   
   # Verify dependencies
   pip install -r requirements.txt
   ```

2. **Lambda function not found**
   ```bash
   # Check if function exists
   aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'my-serverless-app')]"
   
   # Check Terraform state
   cd terraform && terraform show
   ```

4. **Step Functions execution failed**
   ```bash
   # Get execution details
   aws stepfunctions describe-execution --execution-arn <arn>
   
   # Get execution history
   aws stepfunctions get-execution-history --execution-arn <arn>
   ```

5. **Secrets Manager access denied**
   ```bash
   # Check secret exists
   aws secretsmanager list-secrets
   
   # Test secret retrieval
   aws secretsmanager get-secret-value --secret-id my-serverless-app-secrets
   ```

### Debug Mode

Enable debug logging in Lambda functions by setting environment variable:

```bash
# In terraform/lambda.tf, add to environment variables:
LOG_LEVEL = "DEBUG"
```

## 📋 Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | Deploy infrastructure with Terraform | `./scripts/deploy.sh [env]` |
| `test-workflow.sh` | Test Step Functions workflow | `./scripts/test-workflow.sh [env]` |
| `monitor-logs.sh` | Monitor CloudWatch logs | `./scripts/monitor-logs.sh [env] [component]` |

## 📚 Additional Resources

- [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [AWS Step Functions](https://docs.aws.amazon.com/step-functions/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions for AWS](https://github.com/aws-actions)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🤖 Project Generation

This project scaffolding was created using **Claude Code** ⚡ based on the specifications in `prompt.txt`. 

### 🛠️ Generated with Claude Code

This entire AWS serverless application was scaffolded using [Claude Code](https://claude.ai/code) 🚀, Anthropic's AI-powered development assistant. The project structure, Terraform configurations, Lambda functions, Docker containers, and CI/CD pipeline were all generated from the detailed prompt specifications.


### 📝 Original Prompt
The complete project requirements and specifications can be found in `prompt.txt`, which served as the blueprint for generating this production-ready serverless architecture.


### 💰 Costs and  🔣 tokens
```txt
Total cost:            $1.84
Total duration (API):  11m 8.5s
Total duration (wall): 15m 8.4s
Total code changes:    2520 lines added, 44 lines removed
Usage by model:
    claude-3-5-haiku:  2.5k input, 215 output, 0 cache read, 0 cache write
       claude-sonnet:  75 input, 52.4k output, 2.4m cache read, 86.7k cache write
```

---