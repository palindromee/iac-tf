variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "ndsm"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\-_.]+$", var.github_org))
    error_message = "GitHub org must contain only alphanumeric characters, hyphens, underscores, and dots."
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\-_.]+$", var.github_repo))
    error_message = "GitHub repo must contain only alphanumeric characters, hyphens, underscores, and dots."
  }
}

variable "tooling_account_id" {
  description = "AWS account ID where the Terraform state bucket is hosted"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.tooling_account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}