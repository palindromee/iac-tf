# Development App Layer Outputs

# Pass through module outputs
output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.app.autoscaling_group_arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.app.autoscaling_group_name
}

output "autoscaling_group_info" {
  description = "Comprehensive Auto Scaling Group information"
  value       = module.app.autoscaling_group_info
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = module.app.launch_template_id
}

output "launch_template_info" {
  description = "Launch Template information"
  value       = module.app.launch_template_info
}

output "security_group_id" {
  description = "ID of the app security group"
  value       = module.app.security_group_id
}

output "security_group_info" {
  description = "Security group information"
  value       = module.app.security_group_info
}

output "iam_role_arn" {
  description = "ARN of the IAM role for app instances"
  value       = module.app.iam_role_arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = module.app.instance_profile_name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm information"
  value       = module.app.cloudwatch_alarms
}

output "autoscaling_policies" {
  description = "Auto Scaling policy information"
  value       = module.app.autoscaling_policies
}

output "stack_name" {
  description = "Stack name for this layer"
  value       = module.app.stack_name
}

output "environment" {
  description = "Environment name"
  value       = module.app.environment
}

output "project_name" {
  description = "Project name"
  value       = module.app.project_name
}

output "app_layer_info" {
  description = "Information for consumption by other layers"
  value       = module.app.app_layer_info
}

# Environment metadata
output "common_tags" {
  description = "Common tags applied to resources"
  value       = var.common_tags
  sensitive   = true
}