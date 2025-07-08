variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "ndsm"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
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
    Environment = "staging"
    CostCenter  = "staging"
    Owner       = "devops-team"
    Purpose     = "staging-infrastructure"
    Terraform   = "true"
    Repository  = "merck/terraform-infrastructure"
  }
}

# Database Configuration for staging environment
variable "database_config" {
  description = "Database configuration for staging environment"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string

    # Storage configuration
    allocated_storage     = number
    max_allocated_storage = number
    storage_type          = string
    storage_encrypted     = bool

    # Database settings
    db_name  = string
    username = string
    port     = number

    # Backup and maintenance
    backup_retention_period = number
    backup_window           = string
    maintenance_window      = string

    # Multi-AZ and performance
    multi_az                     = bool
    performance_insights_enabled = bool
    monitoring_interval          = number

    # Security
    deletion_protection   = bool
    skip_final_snapshot   = bool
    copy_tags_to_snapshot = bool
  })
  default = {
    engine         = "postgres"
    engine_version = "15.8"
    instance_class = "db.t3.small" # Staging environment

    # Storage configuration
    allocated_storage     = 100
    max_allocated_storage = 500
    storage_type          = "gp3"
    storage_encrypted     = true

    # Database settings
    db_name  = "appdb"
    username = "dbadmin"
    port     = 5432

    # Backup and maintenance
    backup_retention_period = 14
    backup_window           = "03:00-04:00"
    maintenance_window      = "sun:04:00-sun:05:00"

    # Multi-AZ and performance (staging settings)
    multi_az                     = true
    performance_insights_enabled = true
    monitoring_interval          = 60

    # Security
    deletion_protection   = false
    skip_final_snapshot   = false
    copy_tags_to_snapshot = true
  }
}

# Security Group Configuration
variable "security_group_config" {
  description = "Security group configuration for RDS instance"
  type = object({
    description = string
    ingress_rules = list(object({
      description              = string
      from_port                = number
      to_port                  = number
      protocol                 = string
      source_security_group_id = optional(string)
      use_app_sg               = optional(bool, false)
    }))
  })
  default = {
    description = "Security group for RDS PostgreSQL - Staging"
    ingress_rules = [
      {
        description              = "PostgreSQL from App instances"
        from_port                = 5432
        to_port                  = 5432
        protocol                 = "tcp"
        source_security_group_id = null
        use_app_sg               = true # Reference app security group
      }
    ]
  }
}

