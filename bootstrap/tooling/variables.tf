variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "ndsm"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project_name))
    error_message = "Project name must start with letter, contain only alphanumeric and hyphens."
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "ndsm-terraform-state"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens, start and end with alphanumeric."
  }
}

# DynamoDB no longer needed with S3 native locking
# Keeping for backward compatibility in outputs

variable "environment_account_ids" {
  description = "List of AWS account IDs for environment accounts that need access to state bucket"
  type        = list(string)
  default     = [624227065433]

  validation {
    condition = alltrue([
      for id in var.environment_account_ids : can(regex("^[0-9]{12}$", id))
    ])
    error_message = "All account IDs must be 12-digit numbers."
  }
}