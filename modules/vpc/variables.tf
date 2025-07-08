variable "project_name" {
  description = "Name of the project. Used for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod). Used for resource naming and tagging."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_config" {
  description = "VPC configuration object"
  type = object({
    cidr_block           = string
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
    instance_tenancy     = optional(string, "default")
  })

  validation {
    condition     = can(cidrhost(var.vpc_config.cidr_block, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR."
  }
}

variable "subnet_config" {
  description = "Subnet configuration for the VPC"
  type = object({
    public_cidrs   = list(string)
    private_cidrs  = list(string)
    database_cidrs = list(string)
  })

  validation {
    condition = alltrue([
      length(var.subnet_config.public_cidrs) >= 2,
      length(var.subnet_config.private_cidrs) >= 2,
      length(var.subnet_config.database_cidrs) >= 2
    ])
    error_message = "At least 2 subnets are required for each tier for high availability."
  }

  validation {
    condition = alltrue([
      for cidr in concat(
        var.subnet_config.public_cidrs,
        var.subnet_config.private_cidrs,
        var.subnet_config.database_cidrs
      ) : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDR blocks must be valid IPv4 CIDRs."
  }
}

variable "nat_gateway_config" {
  description = "NAT Gateway configuration"
  type = object({
    enabled                = bool
    single_nat_gateway     = optional(bool, false)
    one_nat_gateway_per_az = optional(bool, true)
  })
  default = {
    enabled                = true
    single_nat_gateway     = false
    one_nat_gateway_per_az = true
  }
}

variable "flow_log_config" {
  description = "VPC Flow Log configuration"
  type = object({
    enabled         = bool
    retention_days  = optional(number, 30)
    traffic_type    = optional(string, "ALL")
    log_destination = optional(string, "cloud-watch-logs")
  })
  default = {
    enabled        = true
    retention_days = 30
    traffic_type   = "ALL"
  }

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.flow_log_config.retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention period."
  }

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_config.traffic_type)
    error_message = "Traffic type must be one of: ALL, ACCEPT, REJECT."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.common_tags :
      can(regex("^[a-zA-Z0-9\\s\\._:/=+\\-@]+$", key)) &&
      can(regex("^[a-zA-Z0-9\\s\\._:/=+\\-@]*$", value))
    ])
    error_message = "Tag keys and values must contain only valid characters."
  }
}