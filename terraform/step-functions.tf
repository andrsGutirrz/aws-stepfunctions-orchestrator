# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${local.app_name}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${local.app_name}-step-functions-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.lambda1.arn,
          aws_lambda_function.lambda2.arn,
          aws_lambda_function.lambda3.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/stepfunctions/${local.app_name}-workflow"
  retention_in_days = 14
  tags              = local.common_tags
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "workflow" {
  name       = "${local.app_name}-workflow"
  role_arn   = aws_iam_role.step_functions_role.arn
  type       = "STANDARD"
  
  definition = templatefile("${path.module}/step-functions.json", {
    lambda1_function_arn = aws_lambda_function.lambda1.arn
    lambda2_function_arn = aws_lambda_function.lambda2.arn
    lambda3_function_arn = aws_lambda_function.lambda3.arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.step_functions_logs
  ]
}