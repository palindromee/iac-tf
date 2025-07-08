
locals {
  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.common_tags, {
    Module    = "alb"
    ManagedBy = "terraform"
  })


  alb_name          = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"

  access_logs_enabled = var.alb_config.access_logs.enabled && var.alb_config.access_logs.bucket != ""
}

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

resource "aws_security_group_rule" "ingress" {
  for_each = {
    for idx, rule in var.security_group_config.ingress_rules : idx => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "egress" {
  for_each = {
    for idx, rule in var.security_group_config.egress_rules : idx => rule
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
  security_group_id = aws_security_group.alb.id
}

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

resource "aws_lb_target_group" "app" {
  name             = local.target_group_name
  port             = var.target_group_config.port
  protocol         = var.target_group_config.protocol
  protocol_version = var.target_group_config.protocol_version
  target_type      = var.target_group_config.target_type
  vpc_id           = var.vpc_id

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

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_config.port
  protocol          = var.listener_config.protocol
  ssl_policy        = var.listener_config.protocol == "HTTPS" ? var.listener_config.ssl_policy : null
  certificate_arn   = var.listener_config.protocol == "HTTPS" ? var.listener_config.certificate_arn : null

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

  }

  tags = merge(local.common_tags, {
    Name = "${local.alb_name}-listener-${lower(var.listener_config.protocol)}"
    Type = "Listener"
    Tier = "alb"
  })
}