variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "ndsm"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# State management
variable "state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "ndsm-terraform-state"
}

# Common tags applied to all resources
variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "ndsm"
    Environment = "prod"
    CostCenter  = "production"
    Owner       = "platform-team"
    Purpose     = "production-infrastructure"
    Terraform   = "true"
    Repository  = "merck/terraform-infrastructure"
    Compliance  = "required"
  }
}

variable "app_config" {
  description = "Application configuration"
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
  default = {
    instance_type = "m5.large"              # Production environment
    ami_id        = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1
    key_name      = "aws-prod"
    autoscaling = {
      min_size             = 3
      max_size             = 10
      desired_capacity     = 3
      scale_up_threshold   = 70
      scale_down_threshold = 25
      scale_up_cooldown    = 300
      scale_down_cooldown  = 600
    }
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
  default = {
    description = "Security group for Application instances - Production"
    ingress_rules = [
      {
        description              = "HTTP from ALB"
        from_port                = 80
        to_port                  = 80
        protocol                 = "tcp"
        source_security_group_id = null # Will be set via data source in main.tf
        self                     = false
      },
      {
        description              = "HTTPS from ALB"
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = null # Will be set via data source in main.tf
        self                     = false
      }
    ]
    egress_rules = [
      {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        self        = false
      }
    ]
  }
}

