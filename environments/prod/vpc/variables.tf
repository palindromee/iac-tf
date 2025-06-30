# VPC Layer Variables - Production Environment

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "vpc_config" {
  description = "VPC configuration object"
  type = object({
    cidr_block           = string
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
    instance_tenancy     = optional(string, "default")
  })
}

variable "subnet_config" {
  description = "Subnet configuration for the VPC"
  type = object({
    public_cidrs   = list(string)
    private_cidrs  = list(string)
    database_cidrs = list(string)
  })
}

variable "nat_gateway_config" {
  description = "NAT Gateway configuration"
  type = object({
    enabled                = bool
    single_nat_gateway     = optional(bool, false)
    one_nat_gateway_per_az = optional(bool, true)
  })
}

variable "flow_log_config" {
  description = "VPC Flow Log configuration"
  type = object({
    enabled         = bool
    retention_days  = optional(number, 30)
    traffic_type    = optional(string, "ALL")
    log_destination = optional(string, "cloud-watch-logs")
  })
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}