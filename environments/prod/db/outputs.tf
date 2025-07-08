output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.db.db_instance_id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = module.db.db_instance_arn
}

output "db_instance_endpoint" {
  description = "RDS instance connection endpoint"
  value       = module.db.db_instance_endpoint
  sensitive   = true
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = module.db.db_instance_address
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = module.db.db_instance_port
}

output "db_instance_info" {
  description = "Comprehensive RDS instance information"
  value       = module.db.db_instance_info
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = module.db.security_group_id
}

output "security_group_info" {
  description = "RDS security group information"
  value       = module.db.security_group_info
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = module.db.db_subnet_group_name
}

output "db_subnet_group_info" {
  description = "DB subnet group information"
  value       = module.db.db_subnet_group_info
}

output "db_parameter_group_name" {
  description = "DB parameter group name"
  value       = module.db.db_parameter_group_name
}

output "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = module.db.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = module.db.kms_key_arn
}

output "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN for database password"
  value       = module.db.secrets_manager_secret_arn
}

output "secrets_manager_secret_name" {
  description = "Secrets Manager secret name for database password"
  value       = module.db.secrets_manager_secret_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for PostgreSQL logs"
  value       = module.db.cloudwatch_log_group_name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm information"
  value       = module.db.cloudwatch_alarms
}

output "enhanced_monitoring_role_arn" {
  description = "Enhanced monitoring IAM role ARN (if enabled)"
  value       = module.db.enhanced_monitoring_role_arn
}

output "database_connection_info" {
  description = "Database connection information for applications"
  value       = module.db.database_connection_info
  sensitive   = true
}

output "stack_name" {
  description = "Stack name for this layer"
  value       = module.db.stack_name
}

output "environment" {
  description = "Environment name"
  value       = module.db.environment
}

output "project_name" {
  description = "Project name"
  value       = module.db.project_name
}

output "db_layer_info" {
  description = "Information for consumption by other layers"
  value       = module.db.db_layer_info
  sensitive   = true
}

# Environment metadata
output "common_tags" {
  description = "Common tags applied to resources"
  value       = var.common_tags
  sensitive   = true
}