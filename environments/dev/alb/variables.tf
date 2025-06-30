# ALB Layer Variables - Development Environment

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "alb_config" {
  description = "Application Load Balancer configuration object"
  type = object({
    internal                         = optional(bool, false)
    load_balancer_type               = optional(string, "application")
    ip_address_type                  = optional(string, "ipv4")
    enable_deletion_protection       = optional(bool, false)
    enable_http2                     = optional(bool, true)
    enable_cross_zone_load_balancing = optional(bool, true)
    idle_timeout                     = optional(number, 60)

    # Access logs configuration
    access_logs = optional(object({
      enabled = optional(bool, false)
      bucket  = optional(string, "")
      prefix  = optional(string, "alb-logs")
      }), {
      enabled = false
      bucket  = ""
      prefix  = "alb-logs"
    })
  })
}

variable "target_group_config" {
  description = "Target group configuration for ALB"
  type = object({
    port             = optional(number, 80)
    protocol         = optional(string, "HTTP")
    protocol_version = optional(string, "HTTP1")
    target_type      = optional(string, "instance")

    # Health check configuration
    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 2)
      timeout             = optional(number, 5)
      interval            = optional(number, 30)
      path                = optional(string, "/")
      matcher             = optional(string, "200")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      }), {
      enabled             = true
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
      interval            = 30
      path                = "/"
      matcher             = "200"
      port                = "traffic-port"
      protocol            = "HTTP"
    })

    # Stickiness configuration
    stickiness = optional(object({
      enabled         = optional(bool, false)
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
      }), {
      enabled         = false
      type            = "lb_cookie"
      cookie_duration = 86400
    })
  })
}

variable "listener_config" {
  description = "ALB listener configuration"
  type = object({
    port     = optional(number, 80)
    protocol = optional(string, "HTTP")

    # SSL configuration for HTTPS listeners
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS-1-2-2017-01")
    certificate_arn = optional(string, "")

    # Default action configuration
    default_action = optional(object({
      type = optional(string, "forward")

      # Redirect action for HTTP to HTTPS
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
      }), null)

      # Fixed response action
      fixed_response = optional(object({
        content_type = optional(string, "text/plain")
        message_body = optional(string, "")
        status_code  = optional(string, "200")
      }), null)
      }), {
      type = "forward"
    })
  })
}

variable "security_group_config" {
  description = "Security group configuration for ALB"
  type = object({
    description = optional(string, "Security group for Application Load Balancer")

    # Ingress rules
    ingress_rules = optional(list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string), [])
      self        = optional(bool, false)
    })), [])

    # Egress rules
    egress_rules = optional(list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string), ["0.0.0.0/0"])
      self        = optional(bool, false)
      })), [
      {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        self        = false
      }
    ])
  })
}

# Variables that exist in terraform.tfvars but not needed for ALB layer
# These are declared to avoid warnings but not used in this layer

variable "vpc_config" {
  description = "VPC configuration (not used in ALB layer)"
  type        = any
  default     = null
}

variable "subnet_config" {
  description = "Subnet configuration (not used in ALB layer)"
  type        = any
  default     = null
}

variable "nat_gateway_config" {
  description = "NAT Gateway configuration (not used in ALB layer)"
  type        = any
  default     = null
}

variable "flow_log_config" {
  description = "Flow log configuration (not used in ALB layer)"
  type        = any
  default     = null
}

variable "app_config" {
  description = "Application configuration (not used in ALB layer)"
  type        = any
  default     = null
}

variable "database_config" {
  description = "Database configuration (not used in ALB layer)"
  type        = any
  default     = null
}