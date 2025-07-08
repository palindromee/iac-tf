locals {
  # Resource naming convention: {project}-{environment}-{component}
  name_prefix = "${var.project_name}-${var.environment}"

  # Merge common tags with module
  common_tags = merge(var.common_tags, {
    Module      = "vpc"
    ManagedBy   = "terraform"
    Environment = var.environment
    Project     = var.project_name
  })

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name_prefix
  cidr = var.vpc_config.cidr_block

  azs = local.availability_zones

  # Public subnets configuration
  public_subnets  = var.subnet_config.public_cidrs
  private_subnets = var.subnet_config.private_cidrs

  # Database subnets configuration
  database_subnets                   = var.subnet_config.database_cidrs
  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  create_igw = true

  enable_nat_gateway     = var.nat_gateway_config.enabled
  single_nat_gateway     = var.nat_gateway_config.single_nat_gateway
  one_nat_gateway_per_az = var.nat_gateway_config.one_nat_gateway_per_az

  enable_dns_hostnames = var.vpc_config.enable_dns_hostnames
  enable_dns_support   = var.vpc_config.enable_dns_support

  enable_flow_log                                 = var.flow_log_config.enabled
  create_flow_log_cloudwatch_log_group            = var.flow_log_config.enabled
  create_flow_log_cloudwatch_iam_role             = var.flow_log_config.enabled
  flow_log_destination_type                       = var.flow_log_config.log_destination
  flow_log_traffic_type                           = var.flow_log_config.traffic_type
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_config.retention_days
  flow_log_cloudwatch_log_group_kms_key_id        = var.flow_log_config.enabled ? aws_kms_key.vpc_flow_logs[0].arn : null

  # Tags
  tags = local.common_tags

  public_subnet_tags = merge(local.common_tags, {
    Type = "public"
    Tier = "web"
  })

  private_subnet_tags = merge(local.common_tags, {
    Type = "private"
    Tier = "app"
  })

  database_subnet_tags = merge(local.common_tags, {
    Type = "database"
    Tier = "data"
  })

  igw_tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
    Type = "internet-gateway"
  })

  nat_gateway_tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
    Type = "nat-gateway"
  })

  nat_eip_tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
    Type = "elastic-ip"
  })
}

resource "aws_kms_key" "vpc_flow_logs" {
  count = var.flow_log_config.enabled ? 1 : 0

  description         = "KMS key for VPC Flow Logs encryption - ${local.name_prefix}"
  enable_key_rotation = true

  # Key policy following AWS best practices
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc-flow-log/*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-flow-logs-key"
    Type = "kms-key"
  })
}

resource "aws_kms_alias" "vpc_flow_logs" {
  count = var.flow_log_config.enabled ? 1 : 0

  name          = "alias/${local.name_prefix}-vpc-flow-logs"
  target_key_id = aws_kms_key.vpc_flow_logs[0].key_id
}