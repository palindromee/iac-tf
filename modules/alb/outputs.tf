output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group for ASG attachment"
  value       = aws_lb_target_group.app.arn
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.main.arn
}

output "alb_info" {
  description = "Comprehensive ALB information for cross-layer communication"
  value = {
    id         = aws_lb.main.id
    arn        = aws_lb.main.arn
    dns_name   = aws_lb.main.dns_name
    zone_id    = aws_lb.main.zone_id
    name       = aws_lb.main.name
    type       = aws_lb.main.load_balancer_type
    scheme     = aws_lb.main.internal ? "internal" : "internet-facing"
    vpc_id     = aws_lb.main.vpc_id
    subnet_ids = aws_lb.main.subnets
  }
}

output "target_group_info" {
  description = "Comprehensive target group information"
  value = {
    arn                  = aws_lb_target_group.app.arn
    name                 = aws_lb_target_group.app.name
    port                 = aws_lb_target_group.app.port
    protocol             = aws_lb_target_group.app.protocol
    protocol_version     = aws_lb_target_group.app.protocol_version
    target_type          = aws_lb_target_group.app.target_type
    vpc_id               = aws_lb_target_group.app.vpc_id
    health_check_path    = aws_lb_target_group.app.health_check[0].path
    health_check_matcher = aws_lb_target_group.app.health_check[0].matcher
  }
}

output "security_group_info" {
  description = "Security group information for cross-layer communication"
  value = {
    id          = aws_security_group.alb.id
    arn         = aws_security_group.alb.arn
    name        = aws_security_group.alb.name
    description = aws_security_group.alb.description
    vpc_id      = aws_security_group.alb.vpc_id
  }
}

output "listener_info" {
  description = "Listener configuration information"
  value = {
    arn                 = aws_lb_listener.main.arn
    port                = aws_lb_listener.main.port
    protocol            = aws_lb_listener.main.protocol
    ssl_policy          = aws_lb_listener.main.ssl_policy
    default_action_type = aws_lb_listener.main.default_action[0].type
  }
}

output "app_layer_inputs" {
  description = "Pre-computed values for App layer module consumption"
  value = {
    target_group_arn   = aws_lb_target_group.app.arn
    security_group_id  = aws_security_group.alb.id
    vpc_id             = aws_lb.main.vpc_id
    availability_zones = data.aws_availability_zones.available.names
  }
}

output "stack_name" {
  description = "Stack name for cross-layer references"
  value       = "${var.project_name}-${var.environment}-alb"
}

output "common_tags" {
  description = "Common tags applied to all ALB resources"
  value       = local.common_tags
  sensitive   = true
}