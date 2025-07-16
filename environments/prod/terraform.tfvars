# Production Environment Configuration

# Basic configuration
project_name = "ndsm"
environment  = "prod"
aws_region   = "us-east-1"

# State management
state_bucket = "ndsm-terraform-state"

# Common tags applied to all resources
common_tags = {
  Project     = "ndsm"
  Environment = "prod"
  CostCenter  = "production"
  Owner       = "platform-team"
  Purpose     = "production-infrastructure"
  Terraform   = "true"
  Repository  = "merck/terraform-infrastructure"
  Compliance  = "required"
}

# VPC Configuration using structured object
vpc_config = {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
}

# Subnet configuration organized by tier
subnet_config = {
  public_cidrs = [
    "10.2.1.0/24", # us-east-1a - Web tier
    "10.2.2.0/24", # us-east-1b - Web tier
    "10.2.3.0/24"  # us-east-1c - Web tier
  ]
  private_cidrs = [
    "10.2.11.0/24", # us-east-1a - App tier
    "10.2.12.0/24", # us-east-1b - App tier
    "10.2.13.0/24"  # us-east-1c - App tier
  ]
  database_cidrs = [
    "10.2.21.0/24", # us-east-1a - Data tier
    "10.2.22.0/24", # us-east-1b - Data tier
    "10.2.23.0/24"  # us-east-1c - Data tier
  ]
}

# NAT Gateway configuration for production
nat_gateway_config = {
  enabled                = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
}

# VPC Flow Logs configuration
flow_log_config = {
  enabled         = true
  retention_days  = 30
  traffic_type    = "ALL"
  log_destination = "cloud-watch-logs"
}

# ALB Configuration using structured object
alb_config = {
  internal                         = false
  load_balancer_type               = "application"
  ip_address_type                  = "ipv4"
  enable_deletion_protection       = true
  enable_http2                     = true
  enable_cross_zone_load_balancing = true
  idle_timeout                     = 60

  # Access logs configuration (required for production)
  access_logs = {
    enabled = true
    bucket  = "ndsm-prod-alb-logs"
    prefix  = "alb-logs"
  }
}

# Target Group Configuration
target_group_config = {
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  target_type      = "instance"

  # Health check configuration (stricter for production)
  health_check = {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

}

# Listener Configuration
listener_config = {
  port     = 80
  protocol = "HTTP"

  # SSL configuration (production should use HTTPS)
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = ""

  # Default action configuration
  default_action = {
    type = "forward"
  }
}

# Security Group Configuration
security_group_config = {
  description = "Security group for Application Load Balancer - Production"

  # Ingress rules - production restricts access to specific sources
  ingress_rules = [
    {
      description = "HTTP from corporate networks"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"] # Corporate network ranges
      self        = false
    },
    {
      description = "HTTPS from corporate networks"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"] # Corporate network ranges
      self        = false
    }
  ]

  # Egress rules
  egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      self        = false
    }
  ]
}

# Application Layer Configuration
app_config = {
  instance_type = "m5.large"
  ami_id        = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1

  # Auto Scaling configuration (higher capacity for production)
  autoscaling = {
    min_size         = 3
    max_size         = 10
    desired_capacity = 3

    # Scaling policies (more conservative for production)
    scale_up_threshold   = 70
    scale_down_threshold = 25
    scale_up_cooldown    = 300
    scale_down_cooldown  = 600
  }

  # Key pair for instances
  key_name = "aws-prod"
}

# Database Configuration
database_config = {
  engine         = "postgres"
  engine_version = "15.8"
  instance_class = "db.r5.large"

  # Storage configuration (larger for production)
  allocated_storage     = 500
  max_allocated_storage = 2000
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database settings
  db_name  = "appdb"
  username = "dbadmin"
  port     = 5432

  # Backup and maintenance (longer retention for production)
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Multi-AZ and performance (production settings)
  multi_az            = true
  monitoring_interval = 0

  # Security (protection enabled for production)
  deletion_protection   = true
  skip_final_snapshot   = false
  copy_tags_to_snapshot = true
}