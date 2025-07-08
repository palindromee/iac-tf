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
    Layer = "alb"
  })
}


data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

module "alb" {
  source = "../../../modules/alb"

  project_name = var.project_name
  environment  = var.environment

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.subnet_info.public.ids

  alb_config = var.alb_config

  target_group_config = var.target_group_config

  listener_config = var.listener_config

  security_group_config = var.security_group_config

  common_tags = local.environment_tags
}