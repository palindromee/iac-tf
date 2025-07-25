data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for consistent naming and tagging
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.common_tags, {
    Module = "db"
    Layer  = "database"
    Tier   = "data"
  })
}

resource "aws_kms_key" "rds_encryption" {
  description         = "KMS key for RDS encryption - ${local.name_prefix}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowRDSService"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/instance/${local.name_prefix}-db/postgresql"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-key"
    Type = "KMSKey"
  })
}

resource "aws_kms_alias" "rds_encryption" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds_encryption.key_id
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = var.security_group_config.description
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  for_each = {
    for idx, rule in var.security_group_config.ingress_rules : idx => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  security_group_id = aws_security_group.rds.id

  # Use source_security_group_id if provided, otherwise use cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  cidr_blocks              = each.value.source_security_group_id == null ? each.value.cidr_blocks : null
}

resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${local.name_prefix}-db/postgresql"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.rds_encryption.arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-postgresql-logs"
    Type = "LogGroup"
  })
}


# AWS manages the master password when manage_master_user_password = true
# No need for custom Secrets Manager resources in cross-account scenarios

module "rds" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "~> 6.0"
  identifier = "${local.name_prefix}-db"

  engine               = var.database_config.engine
  engine_version       = var.database_config.engine_version
  instance_class       = var.database_config.instance_class
  family               = "postgres15"
  major_engine_version = "15"

  db_name                     = var.database_config.db_name
  username                    = var.database_config.username
  manage_master_user_password = true # Let AWS manage password for cross-account compatibility
  port                        = var.database_config.port

  allocated_storage     = var.database_config.allocated_storage
  max_allocated_storage = var.database_config.max_allocated_storage
  storage_type          = var.database_config.storage_type
  storage_encrypted     = var.database_config.storage_encrypted
  kms_key_id            = aws_kms_key.rds_encryption.arn

  apply_immediately = var.environment == "dev" ? true : false

  db_subnet_group_name   = var.database_subnet_group_name
  subnet_ids             = var.database_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]


  backup_retention_period    = var.database_config.backup_retention_period
  backup_window              = var.database_config.backup_window
  maintenance_window         = var.database_config.maintenance_window
  auto_minor_version_upgrade = true

  multi_az            = var.database_config.multi_az
  publicly_accessible = false

  monitoring_interval = 0


  enabled_cloudwatch_logs_exports = ["postgresql"]

  deletion_protection              = var.database_config.deletion_protection
  skip_final_snapshot              = var.database_config.skip_final_snapshot
  final_snapshot_identifier_prefix = "${local.name_prefix}-db"

  copy_tags_to_snapshot = var.database_config.copy_tags_to_snapshot

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.postgresql
  ]
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${local.name_prefix}-db-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-cpu-alarm"
    Type = "CloudWatchAlarm"
  })
}

