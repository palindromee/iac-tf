variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "ndsm"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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
    Environment = "dev"
    CostCenter  = "development"
    Owner       = "devops-team"
    Purpose     = "development-infrastructure"
    Terraform   = "true"
    Repository  = "ndsm/terraform-infrastructure"
  }
}

# Database Configuration based on CFN settings
variable "database_config" {
  description = "Database configuration from CFN template"
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
    engine_version = "15.8"        # From CFN template
    instance_class = "db.t3.micro" # Dev environment from CFN

    # Storage configuration
    allocated_storage     = 20
    max_allocated_storage = 100
    storage_type          = "gp3"
    storage_encrypted     = true

    # Database settings
    db_name  = "appdb"   # From CFN template
    username = "dbadmin" # From CFN template
    port     = 5432

    # Backup and maintenance
    backup_retention_period = 7
    backup_window           = "03:00-04:00"
    maintenance_window      = "sun:04:00-sun:05:00"

    # Multi-AZ and performance (dev settings)
    multi_az                     = false
    performance_insights_enabled = false
    monitoring_interval          = 60

    # Security
    deletion_protection   = false
    skip_final_snapshot   = true
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
    description = "Security group for RDS PostgreSQL - Development"
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

