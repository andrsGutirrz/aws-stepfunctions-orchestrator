# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.app_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.app_name}-lambda-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.app_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.app_secrets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "lambda1_logs" {
  name              = "/aws/lambda/${local.app_name}-lambda1"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda2_logs" {
  name              = "/aws/lambda/${local.app_name}-lambda2"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda3_logs" {
  name              = "/aws/lambda/${local.app_name}-lambda3"
  retention_in_days = 14
  tags              = local.common_tags
}

# Lambda Functions
resource "aws_lambda_function" "lambda1" {
  function_name = "${local.app_name}-lambda1"
  role          = aws_iam_role.lambda_execution_role.arn
  package_type  = "Zip"
  filename      = "../dist/lambda1.zip"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT             = local.environment
      SECRETS_MANAGER_SECRET  = aws_secretsmanager_secret.app_secrets.name
      LOCAL_DEVELOPMENT       = "false"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda1_logs
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "lambda2" {
  function_name = "${local.app_name}-lambda2"
  role          = aws_iam_role.lambda_execution_role.arn
  package_type  = "Zip"
  filename      = "../dist/lambda2.zip"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT             = local.environment
      SECRETS_MANAGER_SECRET  = aws_secretsmanager_secret.app_secrets.name
      LOCAL_DEVELOPMENT       = "false"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda2_logs
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "lambda3" {
  function_name = "${local.app_name}-lambda3"
  role          = aws_iam_role.lambda_execution_role.arn
  package_type  = "Zip"
  filename      = "../dist/lambda3.zip"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT             = local.environment
      SECRETS_MANAGER_SECRET  = aws_secretsmanager_secret.app_secrets.name
      LOCAL_DEVELOPMENT       = "false"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda3_logs
  ]

  tags = local.common_tags
}