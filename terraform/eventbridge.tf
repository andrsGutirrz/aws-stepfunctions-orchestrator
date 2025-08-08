# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "${local.app_name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for EventBridge
resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${local.app_name}-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.workflow.arn
      }
    ]
  })
}

# EventBridge Rule (Schedule-based trigger for demo)
resource "aws_cloudwatch_event_rule" "workflow_trigger" {
  name                = "${local.app_name}-workflow-trigger"
  description         = "Trigger ${local.app_name} workflow"
  schedule_expression = var.eventbridge_schedule
  state               = var.eventbridge_enabled ? "ENABLED" : "DISABLED"

  tags = local.common_tags
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "step_functions_target" {
  rule      = aws_cloudwatch_event_rule.workflow_trigger.name
  target_id = "${local.app_name}-step-functions-target"
  arn       = aws_sfn_state_machine.workflow.arn
  role_arn  = aws_iam_role.eventbridge_role.arn

  input = jsonencode({
    "trigger_source" = "eventbridge"
    "timestamp"      = "$${aws.events.event.ingestion-time}"
    "environment"    = local.environment
    "message"        = "Workflow triggered by EventBridge schedule"
  })
}

# Custom EventBridge Rule (for manual triggering via custom events)
resource "aws_cloudwatch_event_rule" "custom_trigger" {
  name        = "${local.app_name}-custom-trigger"
  description = "Custom trigger for ${local.app_name} workflow"
  
  event_pattern = jsonencode({
    "source"      = ["${local.app_name}.trigger"]
    "detail-type" = ["Workflow Trigger"]
  })

  state = "ENABLED"
  tags  = local.common_tags
}

# Custom EventBridge Target
resource "aws_cloudwatch_event_target" "custom_step_functions_target" {
  rule      = aws_cloudwatch_event_rule.custom_trigger.name
  target_id = "${local.app_name}-custom-step-functions-target"
  arn       = aws_sfn_state_machine.workflow.arn
  role_arn  = aws_iam_role.eventbridge_role.arn

  input_transformer {
    input_paths = {
      "detail" = "$.detail"
    }
    input_template = "\"<detail>\""
  }
}