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
  # Environment-specific overrides
  environment_tags = merge(var.common_tags, {
    Layer = "vpc"
  })
}


module "vpc" {
  source = "../../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment

  vpc_config = var.vpc_config

  subnet_config = var.subnet_config

  nat_gateway_config = var.nat_gateway_config

  flow_log_config = var.flow_log_config

  common_tags = local.environment_tags
}