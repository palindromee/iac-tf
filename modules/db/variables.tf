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

variable "database_subnet_ids" {
  description = "List of database subnet IDs for the RDS subnet group"
  type        = list(string)
  validation {
    condition     = length(var.database_subnet_ids) >= 2
    error_message = "At least 2 database subnets required for RDS Multi-AZ."
  }
}

variable "database_subnet_group_name" {
  description = "Name of the database subnet group from VPC module"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "database_config" {
  description = "Database configuration based on CFN template"
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

  validation {
    condition = contains([
      "postgres"
    ], var.database_config.engine)
    error_message = "Database engine must be postgres."
  }

  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium",
      "db.r5.large", "db.r5.xlarge", "db.r5.2xlarge"
    ], var.database_config.instance_class)
    error_message = "Instance class must be a valid RDS instance type."
  }

  validation {
    condition     = var.database_config.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }

  validation {
    condition     = var.database_config.max_allocated_storage >= var.database_config.allocated_storage
    error_message = "Max allocated storage must be greater than or equal to allocated storage."
  }

  validation {
    condition     = var.database_config.backup_retention_period >= 1 && var.database_config.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.database_config.monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }

  validation {
    condition     = var.database_config.port >= 1024 && var.database_config.port <= 65535
    error_message = "Database port must be between 1024 and 65535."
  }
}

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
      cidr_blocks              = optional(list(string))
    }))
  })

  validation {
    condition = alltrue([
      for rule in var.security_group_config.ingress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535
    ])
    error_message = "All ingress from_port values must be between 0 and 65535."
  }
}