# Lambda Function ARNs
output "lambda_function_arns" {
  description = "ARNs of the Lambda functions"
  value = {
    lambda1 = aws_lambda_function.lambda1.arn
    lambda2 = aws_lambda_function.lambda2.arn
    lambda3 = aws_lambda_function.lambda3.arn
  }
}

# Step Functions State Machine
output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.workflow.arn
}

output "step_functions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.workflow.name
}

# EventBridge Rules
output "eventbridge_rule_names" {
  description = "Names of the EventBridge rules"
  value = {
    scheduled_trigger = aws_cloudwatch_event_rule.workflow_trigger.name
    custom_trigger    = aws_cloudwatch_event_rule.custom_trigger.name
  }
}

# Secrets Manager
output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.name
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

# CloudWatch Log Groups
output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    lambda1        = aws_cloudwatch_log_group.lambda1_logs.name
    lambda2        = aws_cloudwatch_log_group.lambda2_logs.name
    lambda3        = aws_cloudwatch_log_group.lambda3_logs.name
    step_functions = aws_cloudwatch_log_group.step_functions_logs.name
  }
}

# IAM Role ARNs
output "iam_role_arns" {
  description = "ARNs of the IAM roles"
  value = {
    lambda_execution = aws_iam_role.lambda_execution_role.arn
    step_functions   = aws_iam_role.step_functions_role.arn
    eventbridge      = aws_iam_role.eventbridge_role.arn
  }
}

# AWS Account and Region Info
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}