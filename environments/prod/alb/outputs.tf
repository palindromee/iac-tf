output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = module.alb.alb_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the target group for ASG attachment"
  value       = module.alb.target_group_arn
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = module.alb.security_group_id
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = module.alb.listener_arn
}

# Structured outputs for complex consumers
output "alb_info" {
  description = "Comprehensive ALB information for App layer consumption"
  value       = module.alb.alb_info
}

output "target_group_info" {
  description = "Comprehensive target group information"
  value       = module.alb.target_group_info
}

output "security_group_info" {
  description = "Security group information for App layer"
  value       = module.alb.security_group_info
}

output "listener_info" {
  description = "Listener configuration information"
  value       = module.alb.listener_info
}

# Pre-computed values for App layer consumption
output "app_layer_inputs" {
  description = "Pre-computed values for App layer module consumption"
  value       = module.alb.app_layer_inputs
}

# Environment configuration
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Stack naming for cross-layer references
output "stack_name" {
  description = "Stack name for cross-layer references"
  value       = module.alb.stack_name
}

# Common tags for consistency
output "common_tags" {
  description = "Common tags applied to all ALB layer resources"
  value       = module.alb.common_tags
  sensitive   = true
}