# Application Layer Variables
# Following CFN template app.yaml structure

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project_name))
    error_message = "Project name must start with letter, contain only alphanumeric and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the Auto Scaling Group"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets required for high availability."
  }
}

variable "target_group_arn" {
  description = "ALB Target Group ARN to associate with Auto Scaling Group"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Application Configuration
variable "app_config" {
  description = "Application layer configuration"
  type = object({
    instance_type = string
    ami_id        = string
    key_name      = string
    autoscaling = object({
      min_size             = number
      max_size             = number
      desired_capacity     = number
      scale_up_threshold   = number
      scale_down_threshold = number
      scale_up_cooldown    = number
      scale_down_cooldown  = number
    })
  })

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "m5.large", "m5.xlarge", "m5.2xlarge"
    ], var.app_config.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }

  validation {
    condition     = var.app_config.autoscaling.min_size >= 1
    error_message = "Minimum ASG size must be at least 1."
  }

  validation {
    condition     = var.app_config.autoscaling.max_size >= var.app_config.autoscaling.min_size
    error_message = "Maximum ASG size must be greater than or equal to minimum size."
  }

  validation {
    condition     = var.app_config.autoscaling.desired_capacity >= var.app_config.autoscaling.min_size && var.app_config.autoscaling.desired_capacity <= var.app_config.autoscaling.max_size
    error_message = "Desired capacity must be between min_size and max_size."
  }
}

# Security Group Configuration
variable "security_group_config" {
  description = "Security group configuration for app instances"
  type = object({
    description = string
    ingress_rules = list(object({
      description              = string
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      source_security_group_id = optional(string)
      self                     = optional(bool, false)
    }))
    egress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string))
      self        = optional(bool, false)
    }))
  })

  validation {
    condition = alltrue([
      for rule in var.security_group_config.ingress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535
    ])
    error_message = "All ingress from_port values must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_config.egress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535
    ])
    error_message = "All egress from_port values must be between 0 and 65535."
  }
}