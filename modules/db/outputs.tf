# Database Layer Outputs

# RDS Instance (from module)
output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_identifier
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.db_instance_arn
}

output "db_instance_endpoint" {
  description = "RDS instance connection endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = module.rds.db_instance_address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "db_instance_info" {
  description = "Comprehensive RDS instance information"
  value = {
    id                = module.rds.db_instance_identifier
    arn               = module.rds.db_instance_arn
    endpoint          = module.rds.db_instance_endpoint
    address           = module.rds.db_instance_address
    port              = module.rds.db_instance_port
    engine            = module.rds.db_instance_engine
    engine_version    = module.rds.db_instance_engine_version_actual
    instance_class    = var.database_config.instance_class
    db_name           = module.rds.db_instance_name
    username          = module.rds.db_instance_username
    multi_az          = var.database_config.multi_az
    storage_type      = var.database_config.storage_type
    allocated_storage = var.database_config.allocated_storage
    storage_encrypted = var.database_config.storage_encrypted
    availability_zone = module.rds.db_instance_availability_zone
  }
  sensitive = true
}

# Security Group
output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "security_group_arn" {
  description = "ARN of the RDS security group"
  value       = aws_security_group.rds.arn
}

output "security_group_info" {
  description = "RDS security group information"
  value = {
    id          = aws_security_group.rds.id
    arn         = aws_security_group.rds.arn
    name        = aws_security_group.rds.name
    description = aws_security_group.rds.description
    vpc_id      = aws_security_group.rds.vpc_id
  }
}

# DB Subnet Group (from module)
output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = module.rds.db_subnet_group_id
}

output "db_subnet_group_arn" {
  description = "DB subnet group ARN"
  value       = module.rds.db_subnet_group_arn
}

output "db_subnet_group_info" {
  description = "DB subnet group information"
  value = {
    name       = module.rds.db_subnet_group_id
    arn        = module.rds.db_subnet_group_arn
    subnet_ids = var.database_subnet_ids
  }
}

# Parameter Group (from module)
output "db_parameter_group_name" {
  description = "DB parameter group name"
  value       = module.rds.db_parameter_group_id
}

output "db_parameter_group_arn" {
  description = "DB parameter group ARN"
  value       = module.rds.db_parameter_group_arn
}

# KMS Key
output "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds_encryption.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = aws_kms_key.rds_encryption.arn
}

output "kms_alias_name" {
  description = "KMS key alias name"
  value       = aws_kms_alias.rds_encryption.name
}

# Secrets Manager (AWS Managed)
output "secrets_manager_secret_arn" {
  description = "AWS managed secret ARN for database master password"
  value       = module.rds.db_instance_master_user_secret_arn
}

output "secrets_manager_secret_name" {
  description = "AWS managed secret name for database master password"
  value       = "rds-db-credentials/${module.rds.db_instance_resource_id}/masteruser"
}

# CloudWatch Logs
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for PostgreSQL logs"
  value       = aws_cloudwatch_log_group.postgresql.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for PostgreSQL logs"
  value       = aws_cloudwatch_log_group.postgresql.arn
}

# CloudWatch Alarms
output "cloudwatch_alarms" {
  description = "CloudWatch alarm information"
  value = {
    cpu_alarm_arn          = aws_cloudwatch_metric_alarm.database_cpu.arn
    connections_alarm_arn  = aws_cloudwatch_metric_alarm.database_connections.arn
    memory_alarm_arn       = aws_cloudwatch_metric_alarm.database_freeable_memory.arn
    cpu_alarm_name         = aws_cloudwatch_metric_alarm.database_cpu.alarm_name
    connections_alarm_name = aws_cloudwatch_metric_alarm.database_connections.alarm_name
    memory_alarm_name      = aws_cloudwatch_metric_alarm.database_freeable_memory.alarm_name
  }
}

# Enhanced Monitoring Role (conditional)
output "enhanced_monitoring_role_arn" {
  description = "Enhanced monitoring IAM role ARN (if enabled)"
  value       = var.database_config.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

# Database Connection Information (for application configuration)
output "database_connection_info" {
  description = "Database connection information for applications"
  value = {
    host       = module.rds.db_instance_address
    port       = module.rds.db_instance_port
    database   = module.rds.db_instance_name
    username   = module.rds.db_instance_username
    engine     = module.rds.db_instance_engine
    secret_arn = module.rds.db_instance_master_user_secret_arn
  }
  sensitive = true
}

# Stack Information
output "stack_name" {
  description = "Stack name for this layer"
  value       = "${var.project_name}-${var.environment}-db"
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
output "db_layer_info" {
  description = "Information for consumption by other layers"
  value = {
    security_group_id = aws_security_group.rds.id
    endpoint          = module.rds.db_instance_endpoint
    port              = module.rds.db_instance_port
    database_name     = module.rds.db_instance_name
    secret_arn        = module.rds.db_instance_master_user_secret_arn
    environment       = var.environment
    project_name      = var.project_name
  }
  sensitive = true
}