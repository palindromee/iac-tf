# ALB Module - Application Load Balancer Layer
# Following Terraform best practices for module composition and locals usage

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for strategic computation and naming
locals {
  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Tag merging with hierarchy
  common_tags = merge(var.common_tags, {
    Module    = "alb"
    ManagedBy = "terraform"
  })

  # Security group rules mapping for dynamic creation
  security_group_rules = {
    ingress = var.security_group_config.ingress_rules
    egress  = var.security_group_config.egress_rules
  }

  # ALB configuration with computed values
  alb_name          = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"

  # Access logs configuration
  access_logs_enabled = var.alb_config.access_logs.enabled && var.alb_config.access_logs.bucket != ""
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  vpc_id      = var.vpc_id
  description = var.security_group_config.description

  tags = merge(local.common_tags, {
    Name = "${local.alb_name}-sg"
    Type = "SecurityGroup"
    Tier = "alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Dynamic ingress rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for idx, rule in var.security_group_config.ingress_rules : idx => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.self ? null : each.value.cidr_blocks
  self              = each.value.self ? true : null
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

# Dynamic egress rules
resource "aws_security_group_rule" "egress" {
  for_each = {
    for idx, rule in var.security_group_config.egress_rules : idx => rule
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.self ? null : each.value.cidr_blocks
  self              = each.value.self ? true : null
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = var.alb_config.internal
  load_balancer_type = var.alb_config.load_balancer_type
  ip_address_type    = var.alb_config.ip_address_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.alb_config.enable_deletion_protection
  enable_http2                     = var.alb_config.enable_http2
  enable_cross_zone_load_balancing = var.alb_config.enable_cross_zone_load_balancing
  idle_timeout                     = var.alb_config.idle_timeout

  # Access logs configuration (conditional)
  dynamic "access_logs" {
    for_each = local.access_logs_enabled ? [1] : []
    content {
      bucket  = var.alb_config.access_logs.bucket
      prefix  = var.alb_config.access_logs.prefix
      enabled = var.alb_config.access_logs.enabled
    }
  }

  tags = merge(local.common_tags, {
    Name = local.alb_name
    Type = "LoadBalancer"
    Tier = "alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group for instances
resource "aws_lb_target_group" "app" {
  name             = local.target_group_name
  port             = var.target_group_config.port
  protocol         = var.target_group_config.protocol
  protocol_version = var.target_group_config.protocol_version
  target_type      = var.target_group_config.target_type
  vpc_id           = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = var.target_group_config.health_check.enabled
    healthy_threshold   = var.target_group_config.health_check.healthy_threshold
    unhealthy_threshold = var.target_group_config.health_check.unhealthy_threshold
    timeout             = var.target_group_config.health_check.timeout
    interval            = var.target_group_config.health_check.interval
    path                = var.target_group_config.health_check.path
    matcher             = var.target_group_config.health_check.matcher
    port                = var.target_group_config.health_check.port
    protocol            = var.target_group_config.health_check.protocol
  }

  # Stickiness configuration (conditional)
  dynamic "stickiness" {
    for_each = var.target_group_config.stickiness.enabled ? [1] : []
    content {
      type            = var.target_group_config.stickiness.type
      cookie_duration = var.target_group_config.stickiness.cookie_duration
      enabled         = var.target_group_config.stickiness.enabled
    }
  }

  # Deregistration delay for faster deployments in non-prod
  deregistration_delay = var.environment == "prod" ? 300 : 30

  tags = merge(local.common_tags, {
    Name = local.target_group_name
    Type = "TargetGroup"
    Tier = "alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_config.port
  protocol          = var.listener_config.protocol
  ssl_policy        = var.listener_config.protocol == "HTTPS" ? var.listener_config.ssl_policy : null
  certificate_arn   = var.listener_config.protocol == "HTTPS" ? var.listener_config.certificate_arn : null

  # Default action based on configuration
  default_action {
    type = var.listener_config.default_action.type

    # Forward action (default)
    dynamic "forward" {
      for_each = var.listener_config.default_action.type == "forward" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.app.arn
        }
      }
    }

    # Redirect action
    dynamic "redirect" {
      for_each = var.listener_config.default_action.type == "redirect" ? [1] : []
      content {
        port        = var.listener_config.default_action.redirect.port
        protocol    = var.listener_config.default_action.redirect.protocol
        status_code = var.listener_config.default_action.redirect.status_code
      }
    }

    # Fixed response action
    dynamic "fixed_response" {
      for_each = var.listener_config.default_action.type == "fixed-response" ? [1] : []
      content {
        content_type = var.listener_config.default_action.fixed_response.content_type
        message_body = var.listener_config.default_action.fixed_response.message_body
        status_code  = var.listener_config.default_action.fixed_response.status_code
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.alb_name}-listener-${lower(var.listener_config.protocol)}"
    Type = "Listener"
    Tier = "alb"
  })
}