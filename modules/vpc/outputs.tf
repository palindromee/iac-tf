# VPC Module Outputs
# Following Terraform best practices for output organization and naming

# Core VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# Networking Components
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

# Subnet Information - grouped by type
output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = module.vpc.public_subnet_arns
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = module.vpc.private_subnet_arns
}

output "database_subnets" {
  description = "List of database subnet IDs"
  value       = module.vpc.database_subnets
}

output "database_subnet_arns" {
  description = "List of database subnet ARNs"
  value       = module.vpc.database_subnet_arns
}

output "database_subnet_group" {
  description = "ID of the database subnet group"
  value       = module.vpc.database_subnet_group
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

# NAT Gateway Information
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IP addresses of NAT Gateways"
  value       = module.vpc.nat_public_ips
}

# Route Table Information
output "public_route_table_ids" {
  description = "List of public route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of database route table IDs"
  value       = module.vpc.database_route_table_ids
}

# Availability Zone Information
output "availability_zones" {
  description = "List of availability zones used by the VPC"
  value       = module.vpc.azs
}

# VPC Flow Logs
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "ARN of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "vpc_flow_log_destination_type" {
  description = "Type of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_type
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "ARN of the IAM role used when pushing logs to CloudWatch log group"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

output "vpc_flow_logs_kms_key_id" {
  description = "KMS Key ID used for VPC Flow Logs encryption"
  value       = var.flow_log_config.enabled ? aws_kms_key.vpc_flow_logs[0].key_id : null
}

output "vpc_flow_logs_kms_key_arn" {
  description = "KMS Key ARN used for VPC Flow Logs encryption"
  value       = var.flow_log_config.enabled ? aws_kms_key.vpc_flow_logs[0].arn : null
}

# Module Information
output "name_prefix" {
  description = "Name prefix used for resource naming"
  value       = local.name_prefix
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
  sensitive   = true
}

# Structured outputs for complex consumers
output "network_info" {
  description = "Comprehensive network information"
  value = {
    vpc_id              = module.vpc.vpc_id
    vpc_cidr            = module.vpc.vpc_cidr_block
    availability_zones  = module.vpc.azs
    internet_gateway_id = module.vpc.igw_id
    nat_gateway_enabled = var.nat_gateway_config.enabled
    flow_logs_enabled   = var.flow_log_config.enabled
  }
}

output "subnet_info" {
  description = "Structured subnet information for all tiers"
  value = {
    public = {
      ids   = module.vpc.public_subnets
      arns  = module.vpc.public_subnet_arns
      cidrs = var.subnet_config.public_cidrs
      type  = "public"
      tier  = "web"
    }
    private = {
      ids   = module.vpc.private_subnets
      arns  = module.vpc.private_subnet_arns
      cidrs = var.subnet_config.private_cidrs
      type  = "private"
      tier  = "app"
    }
    database = {
      ids               = module.vpc.database_subnets
      arns              = module.vpc.database_subnet_arns
      cidrs             = var.subnet_config.database_cidrs
      type              = "database"
      tier              = "data"
      subnet_group_name = module.vpc.database_subnet_group_name
    }
  }
}