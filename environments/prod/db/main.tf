# Production Database Layer

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
  environment_tags = merge(var.common_tags, {
    Layer = "database"
  })
}

# Data sources for cross-layer dependencies
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get VPC information from remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Get App information from remote state for security group reference
data "terraform_remote_state" "app" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/app/terraform.tfstate"
    region = var.aws_region
  }
}

# Database Module instantiation
module "db" {
  source = "../../../modules/db"

  # Basic configuration
  project_name = var.project_name
  environment  = var.environment

  # Network configuration from VPC layer
  vpc_id                     = data.terraform_remote_state.vpc.outputs.vpc_id
  database_subnet_ids        = data.terraform_remote_state.vpc.outputs.database_subnet_ids
  database_subnet_group_name = data.terraform_remote_state.vpc.outputs.database_subnet_group_name

  # Database configuration from variables
  database_config = var.database_config

  # Security Group configuration (using VPC CIDR for initial deployment)
  security_group_config = {
    description = var.security_group_config.description
    ingress_rules = [
      for rule in var.security_group_config.ingress_rules : {
        description              = rule.description
        from_port                = rule.from_port
        to_port                  = rule.to_port
        protocol                 = rule.protocol
        source_security_group_id = null                                                     # Will be updated after app layer is deployed
        cidr_blocks              = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block] # Use VPC CIDR for now
      }
    ]
  }

  # Tags
  common_tags = local.environment_tags
}