output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets for ALB"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets for application"
  value       = module.vpc.private_subnets
}

output "database_subnet_ids" {
  description = "List of IDs of the database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs used by NAT Gateways"
  value       = module.vpc.nat_public_ips
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "stack_name" {
  description = "Stack name for cross-layer references"
  value       = "${var.project_name}-${var.environment}-vpc"
}

output "network_info" {
  description = "Comprehensive network information for other layers"
  value       = module.vpc.network_info
}

output "subnet_info" {
  description = "Structured subnet information for all tiers"
  value       = module.vpc.subnet_info
}
