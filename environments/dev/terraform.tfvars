# Development Environment Configuration

project_name = "ndsm"
environment  = "dev"
aws_region   = "us-east-1"

# State management
state_bucket = "ndsm-terraform-state"

# Common tags applied to all resources
common_tags = {
  Project     = "ndsm"
  Environment = "dev"
  CostCenter  = "development"
  Owner       = "devops-team"
  Purpose     = "development-infrastructure"
  Terraform   = "true"
  Repository  = "merck/terraform-infrastructure"
}

vpc_config = {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
}

subnet_config = {
  public_cidrs = [
    "10.0.1.0/24", # us-east-1a - Web tier
    "10.0.2.0/24", # us-east-1b - Web tier
    "10.0.3.0/24"  # us-east-1c - Web tier
  ]
  private_cidrs = [
    "10.0.11.0/24", # us-east-1a - App tier
    "10.0.12.0/24", # us-east-1b - App tier
    "10.0.13.0/24"  # us-east-1c - App tier
  ]
  database_cidrs = [
    "10.0.21.0/24", # us-east-1a - Data tier
    "10.0.22.0/24", # us-east-1b - Data tier
    "10.0.23.0/24"  # us-east-1c - Data tier
  ]
}

nat_gateway_config = {
  enabled                = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
}

flow_log_config = {
  enabled         = true
  retention_days  = 7
  traffic_type    = "ALL"
  log_destination = "cloud-watch-logs"
}

alb_config = {
  internal                         = false
  load_balancer_type               = "application"
  ip_address_type                  = "ipv4"
  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true
  idle_timeout                     = 60

  access_logs = {
    enabled = false
    bucket  = ""
    prefix  = "alb-logs"
  }
}


target_group_config = {
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  target_type      = "instance"

  health_check = {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

}

listener_config = {
  port     = 80
  protocol = "HTTP"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = ""

  default_action = {
    type = "forward"
  }
}

security_group_config = {
  description = "Security group for Application Load Balancer - Development"

  # Ingress rules - dev allows from anywhere, prod should be restricted
  ingress_rules = [
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Dev only - restrict for prod
      self        = false
    },
    {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Dev only - restrict for prod
      self        = false
    }
  ]

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
  instance_type = "t3.micro"
  ami_id        = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1

  autoscaling = {
    min_size         = 1
    max_size         = 2
    desired_capacity = 1

    scale_up_threshold   = 70
    scale_down_threshold = 25
    scale_up_cooldown    = 300
    scale_down_cooldown  = 300
  }

  key_name = "aws-demo"
}

database_config = {
  engine         = "postgres"
  engine_version = "15.8"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "appdb"
  username = "dbadmin"
  port     = 5432

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Multi-AZ and performance
  multi_az                     = false
  monitoring_interval          = 0
  performance_insights_enabled = false

  # Security
  deletion_protection   = false
  skip_final_snapshot   = true
  copy_tags_to_snapshot = true
}