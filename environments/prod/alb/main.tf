# Production ALB Layer

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
    Layer = "alb"
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data source to get VPC layer outputs
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# ALB Module instantiation
module "alb" {
  source = "../../../modules/alb"

  # Basic configuration
  project_name = var.project_name
  environment  = var.environment

  # VPC data from remote state (cross-layer communication)
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.subnet_info.public.ids

  # ALB configuration from variables
  alb_config = var.alb_config

  # Target group configuration
  target_group_config = var.target_group_config

  # Listener configuration
  listener_config = var.listener_config

  # Security group configuration
  security_group_config = var.security_group_config

  # Tags
  common_tags = local.environment_tags
}