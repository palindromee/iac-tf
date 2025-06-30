# Application Layer Outputs

# Auto Scaling Group (from module)
output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_name
}

output "autoscaling_group_info" {
  description = "Comprehensive Auto Scaling Group information"
  value = {
    arn                 = module.autoscaling.autoscaling_group_arn
    name                = module.autoscaling.autoscaling_group_name
    min_size            = module.autoscaling.autoscaling_group_min_size
    max_size            = module.autoscaling.autoscaling_group_max_size
    desired_capacity    = module.autoscaling.autoscaling_group_desired_capacity
    vpc_zone_identifier = module.autoscaling.autoscaling_group_vpc_zone_identifier
    target_group_arns   = module.autoscaling.autoscaling_group_target_group_arns
    health_check_type   = module.autoscaling.autoscaling_group_health_check_type
  }
}

# Launch Template (from module)
output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = module.autoscaling.launch_template_id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = module.autoscaling.launch_template_latest_version
}

output "launch_template_info" {
  description = "Launch Template information"
  value = {
    id              = module.autoscaling.launch_template_id
    name            = module.autoscaling.launch_template_name
    latest_version  = module.autoscaling.launch_template_latest_version
    default_version = module.autoscaling.launch_template_default_version
    instance_type   = var.app_config.instance_type
    image_id        = var.app_config.ami_id
    key_name        = var.app_config.key_name
  }
}

# Security Group
output "security_group_id" {
  description = "ID of the app security group"
  value       = aws_security_group.app.id
}

output "security_group_arn" {
  description = "ARN of the app security group"
  value       = aws_security_group.app.arn
}

output "security_group_info" {
  description = "Security group information"
  value = {
    id          = aws_security_group.app.id
    arn         = aws_security_group.app.arn
    name        = aws_security_group.app.name
    description = aws_security_group.app.description
    vpc_id      = aws_security_group.app.vpc_id
  }
}

# IAM Resources
output "iam_role_arn" {
  description = "ARN of the IAM role for app instances"
  value       = aws_iam_role.app_instance_role.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for app instances"
  value       = aws_iam_role.app_instance_role.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = aws_iam_instance_profile.app_instance_profile.arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.app_instance_profile.name
}

# CloudWatch Alarms
output "cloudwatch_alarms" {
  description = "CloudWatch alarm information"
  value = {
    cpu_high_alarm_arn  = aws_cloudwatch_metric_alarm.cpu_high.arn
    cpu_low_alarm_arn   = aws_cloudwatch_metric_alarm.cpu_low.arn
    cpu_high_alarm_name = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
    cpu_low_alarm_name  = aws_cloudwatch_metric_alarm.cpu_low.alarm_name
  }
}

# Auto Scaling Policies (from module)
output "autoscaling_policies" {
  description = "Auto Scaling policy information"
  value = {
    scale_up_policy_arn    = module.autoscaling.autoscaling_policy_arns["scale_up"]
    scale_down_policy_arn  = module.autoscaling.autoscaling_policy_arns["scale_down"]
    scale_up_policy_name   = "${local.name_prefix}-app-scale-up"
    scale_down_policy_name = "${local.name_prefix}-app-scale-down"
  }
}

# Stack Information
output "stack_name" {
  description = "Stack name for this layer"
  value       = "${var.project_name}-${var.environment}-app"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# For use by other layers
output "app_layer_info" {
  description = "Information for consumption by other layers"
  value = {
    autoscaling_group_name = module.autoscaling.autoscaling_group_name
    security_group_id      = aws_security_group.app.id
    iam_role_arn           = aws_iam_role.app_instance_role.arn
    launch_template_id     = module.autoscaling.launch_template_id
    environment            = var.environment
    project_name           = var.project_name
  }
}