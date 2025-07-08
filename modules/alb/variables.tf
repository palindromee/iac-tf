variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name must not be empty."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition = contains([
      "dev", "staging", "prod", "test"
    ], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for ALB deployment"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets required for ALB deployment."
  }

  validation {
    condition = alltrue([
      for subnet_id in var.subnet_ids : can(regex("^subnet-", subnet_id))
    ])
    error_message = "All subnet IDs must be valid subnet identifiers."
  }
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

  validation {
    condition = contains([
      "application", "network", "gateway"
    ], var.alb_config.load_balancer_type)
    error_message = "Load balancer type must be application, network, or gateway."
  }

  validation {
    condition = contains([
      "ipv4", "dualstack"
    ], var.alb_config.ip_address_type)
    error_message = "IP address type must be ipv4 or dualstack."
  }

  validation {
    condition     = var.alb_config.idle_timeout >= 1 && var.alb_config.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
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

  })

  validation {
    condition = contains([
      "HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP", "GENEVE"
    ], var.target_group_config.protocol)
    error_message = "Protocol must be HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP, or GENEVE."
  }

  validation {
    condition = contains([
      "HTTP1", "HTTP2", "GRPC"
    ], var.target_group_config.protocol_version)
    error_message = "Protocol version must be HTTP1, HTTP2, or GRPC."
  }

  validation {
    condition = contains([
      "instance", "ip", "lambda", "alb"
    ], var.target_group_config.target_type)
    error_message = "Target type must be instance, ip, lambda, or alb."
  }

  validation {
    condition = (
      var.target_group_config.health_check.healthy_threshold >= 2 &&
      var.target_group_config.health_check.healthy_threshold <= 10
    )
    error_message = "Healthy threshold must be between 2 and 10."
  }

  validation {
    condition = (
      var.target_group_config.health_check.unhealthy_threshold >= 2 &&
      var.target_group_config.health_check.unhealthy_threshold <= 10
    )
    error_message = "Unhealthy threshold must be between 2 and 10."
  }

  validation {
    condition = (
      var.target_group_config.health_check.timeout >= 2 &&
      var.target_group_config.health_check.timeout <= 120
    )
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }

  validation {
    condition = (
      var.target_group_config.health_check.interval >= 5 &&
      var.target_group_config.health_check.interval <= 300
    )
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "listener_config" {
  description = "ALB listener configuration"
  type = object({
    port     = optional(number, 80)
    protocol = optional(string, "HTTP")

    # SSL configuration for HTTPS listeners
    ssl_policy      = optional(string, "ELBSecurityPolicy-2016-08")
    certificate_arn = optional(string, "")

    # Default action configuration
    default_action = optional(object({
      type = optional(string, "forward")

      }), {
      type = "forward"
    })
  })

  validation {
    condition = contains([
      "HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP"
    ], var.listener_config.protocol)
    error_message = "Listener protocol must be HTTP, HTTPS, TCP, TLS, UDP, or TCP_UDP."
  }

  validation {
    condition = (
      var.listener_config.port >= 1 &&
      var.listener_config.port <= 65535
    )
    error_message = "Listener port must be between 1 and 65535."
  }

  validation {
    condition = contains([
      "forward", "authenticate-cognito", "authenticate-oidc"
    ], var.listener_config.default_action.type)
    error_message = "Default action type must be forward, authenticate-cognito, or authenticate-oidc."
  }
}

variable "security_group_config" {
  description = "Security group configuration for ALB"
  type = object({
    description = optional(string, "Security group for Application Load Balancer")

    # Simple ingress rules - allow HTTP/HTTPS from internet
    ingress_rules = optional(list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      })), [
      {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ])

    # Simple egress rules - allow all outbound
    egress_rules = optional(list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      })), [
      {
        description = "All outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ])
  })
}