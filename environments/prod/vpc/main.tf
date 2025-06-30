# Production VPC Layer

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided during initialization
    # terraform init -backend-config="bucket=your-state-bucket"
  }
}

# Provider configuration with default tags
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }
}

# Local values for environment-specific configuration
locals {
  # Environment-specific overrides
  environment_tags = merge(var.common_tags, {
    Layer = "vpc"
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC Module instantiation
module "vpc" {
  source = "../../../modules/vpc"

  # Basic configuration
  project_name = var.project_name
  environment  = var.environment

  # VPC configuration from variables
  vpc_config = var.vpc_config

  # Subnet configuration
  subnet_config = var.subnet_config

  # NAT Gateway configuration
  nat_gateway_config = var.nat_gateway_config

  # VPC Flow Logs configuration
  flow_log_config = var.flow_log_config

  # Tags
  common_tags = local.environment_tags
}