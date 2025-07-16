
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.common_tags, {
    Module = "app"
    Layer  = "application"
    Tier   = "app"
  })
}

resource "aws_iam_role" "app_instance_role" {
  name = "${local.name_prefix}-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-instance-role"
    Type = "IAMRole"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.app_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "${local.name_prefix}-app-instance-profile"
  role = aws_iam_role.app_instance_role.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-instance-profile"
    Type = "InstanceProfile"
  })
}

resource "aws_security_group" "app" {
  name_prefix = "${local.name_prefix}-app-"
  description = var.security_group_config.description
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_ingress" {
  for_each = {
    for idx, rule in var.security_group_config.ingress_rules : idx => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  security_group_id = aws_security_group.app.id

  cidr_blocks              = each.value.self == false && each.value.source_security_group_id == null ? each.value.cidr_blocks : null
  source_security_group_id = each.value.source_security_group_id
  self                     = each.value.self == true ? true : null
}

resource "aws_security_group_rule" "app_egress" {
  for_each = {
    for idx, rule in var.security_group_config.egress_rules : idx => rule
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  security_group_id = aws_security_group.app.id

  cidr_blocks = each.value.self == false ? each.value.cidr_blocks : null
  self        = each.value.self == true ? true : null
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  # Autoscaling group
  name                      = "${local.name_prefix}-app-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.app_config.autoscaling.min_size
  max_size         = var.app_config.autoscaling.max_size
  desired_capacity = var.app_config.autoscaling.desired_capacity

  launch_template_name        = "${local.name_prefix}-app-lt"
  launch_template_description = "Launch template for ${local.name_prefix} application instances"
  update_default_version      = true

  image_id        = var.app_config.ami_id
  instance_type   = var.app_config.instance_type
  key_name        = var.app_config.key_name
  security_groups = [aws_security_group.app.id]

  iam_instance_profile_name = aws_iam_instance_profile.app_instance_profile.name

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }


  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    project     = var.project_name
  }))

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  # Scaling policies
  scaling_policies = {
    scale_up = {
      policy_type        = "StepScaling"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = 1
      cooldown           = var.app_config.autoscaling.scale_up_cooldown
    }
    scale_down = {
      policy_type        = "StepScaling"
      adjustment_type    = "ChangeInCapacity"
      scaling_adjustment = -1
      cooldown           = var.app_config.autoscaling.scale_down_cooldown
    }
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.app_config.autoscaling.scale_up_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization for scale up"
  alarm_actions       = [module.autoscaling.autoscaling_policy_arns["scale_up"]]

  dimensions = {
    AutoScalingGroupName = module.autoscaling.autoscaling_group_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-cpu-high"
    Type = "CloudWatchAlarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name_prefix}-app-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.app_config.autoscaling.scale_down_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization for scale down"
  alarm_actions       = [module.autoscaling.autoscaling_policy_arns["scale_down"]]

  dimensions = {
    AutoScalingGroupName = module.autoscaling.autoscaling_group_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-cpu-low"
    Type = "CloudWatchAlarm"
  })
}