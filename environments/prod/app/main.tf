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

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }
}

# Local values for environment-specific configuration
locals {
  environment_tags = merge(var.common_tags, {
    Layer = "app"
  })
}


# Get VPC information from remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Get ALB information from remote state
data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/alb/terraform.tfstate"
    region = var.aws_region
  }
}

module "app" {
  source = "../../../modules/app"

  # Basic configuration
  project_name = var.project_name
  environment  = var.environment

  # Network configuration from VPC layer
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  # ALB configuration from ALB layer
  target_group_arn = data.terraform_remote_state.alb.outputs.target_group_arn

  # App configuration from variables
  app_config = var.app_config

  # Security Group configuration with ALB security group reference
  security_group_config = merge(var.security_group_config, {
    ingress_rules = [
      for rule in var.security_group_config.ingress_rules : merge(rule, {
        source_security_group_id = (rule.from_port == 80 || rule.from_port == 443) ? data.terraform_remote_state.alb.outputs.security_group_id : rule.source_security_group_id
      })
    ]
  })

  # Tags
  common_tags = local.environment_tags
}