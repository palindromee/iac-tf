# AWS Multi-Tier Infrastructure Platform

Streamlined infrastructure deployment with [Terraform](https://www.terraform.io/) IaC, [GitHub Actions](https://docs.github.com/en/actions) CI/CD, and built-in security best practices across environments. Extensible to deploy multi-environment infrastructure across AWS accounts.

## Table of Contents

1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Key Features Implemented](#key-features-implemented)
4. [Enhancement Opportunities (WIP)](#enhancement-opportunities-wip)
5. [Challenges Faced](#challenges-faced)
6. [General Cost Optimization Opportunities in AWS](#general-cost-optimization-opportunities-in-aws)
7. [Prerequisites](#prerequisites)
8. [Demo](#demo)
   - [Environment Configuration](#environment-configuration)
   - [GitHub Actions Pipeline Stages](#github-actions-pipeline-stages)
   - [AWS Terraform Modules Deployed](#aws-terraform-modules-deployed)
   - [Infrastructure Resources Created](#infrastructure-resources-created)

## Overview

<img src="assets/GHA-Terraform Workflow.png" alt="GHA-Terraform Workflow" width="800" />

The CI/CD pipeline follows a sequential execution model: Lint/Scan → Dev → Staging → Production. 

Each stage must complete successfully before the next begins, ensuring quality gates and preventing broken deployments from propagating through environments.

## Repository Structure

```
.
├── .github/workflows/          # GitHub Actions CI/CD orchestration
│   ├── main.yml               # Main orchestrator workflow
│   ├── lint-and-scan.yml      # Security and quality checks
│   └── deploy-*.yml           # Environment-specific deployments
│
├── .github/actions/           # GitHub Composite Actions for workflow optimization
│   ├── terraform-setup/       # Reusable Terraform environment setup
│   └── terraform-layer-deploy/ # Reusable Terraform deployment logic
│
├── .checkov/                  # Custom security policies
│   └── terraform-custom-policies.yaml # Organization-specific compliance rules
│
├── bootstrap/                 # Initial setup and OIDC configuration
│   ├── README.md             # Detailed setup instructions
│   ├── tooling/              # S3 backend for TF statefiles and KMS setup
│   └── environment/          # OIDC providers and IAM roles
│
├── modules/                   # Reusable Terraform modules
│   ├── vpc/                  # Network/VPC layer
│   ├── alb/                  # ALB layer
│   ├── app/                  # Application layer
│   └── db/                   # Database layer
│
├── .terraform-version         # Terraform version pinning (1.9.8)
├── .tflint.hcl               # TFLint configuration for static analysis
├── terraform.tf             # Root provider configuration
│
└── environments/             # Environment-specific configurations
    ├── dev/                  # Development
    ├── staging/              # Staging
    └── prod/                 # Production
```

## Key Features Implemented

1. **Security-First Approach & DevSecOps Culture**
   - ✅ **[Shift-left security](https://www.fortinet.com/resources/cyberglossary/shift-left-security)**: Security safeguards embedded at the beginning of CI/CD pipeline (Lint/Scan stage)
   - ✅ [OIDC authentication using GitHub + AWS](https://docs.github.com/en/actions/how-tos/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) replaces IAM access keys for secure, temporary credentials
   - ✅ Dedicated IAM roles per environment with least-privilege access
   - ✅ Zero static credentials stored in GitHub or code
   - ✅ Custom [Checkov](https://www.checkov.io/) policies enable organization-specific compliance enforcement alongside default policies

2. **Modular Design**
   - ✅ Each infrastructure layer (VPC, ALB, App, DB) deployed via separate Terraform modules
   - ✅ Cross-layer references provide loose coupling between components (using Terraform data sources)
   - ✅ Environment isolation achieved with separate state files per layer and environments in different folders
   - ✅ Independent lifecycle management for each layer

3. **GitHub Actions Pipeline with Embedded Security**
   - ✅ **[DevSecOps](https://www.fortinet.com/resources/cyberglossary/devsecops) implementation**: Enforced Lint/Scan → Dev → Staging → Production flow with security gates preventing deployment of non-compliant infrastructure
   - ✅ Reusable workflows for modular CI/CD operations
   - ✅ **Shift-left security scanning**: Terraform fmt, [TFLint](https://github.com/terraform-linters/tflint) (static analysis), [Checkov](https://www.checkov.io/) (Policy as Code with default + custom policies), and [TruffleHog](https://github.com/trufflesecurity/trufflehog) (Secrets scanner) run before any deployment
   - ✅ Environment-specific deployment workflows with proper job dependencies
   - ✅ Environment-specific secrets stored in GitHub Actions (e.g., AWS IAM Role ARNs, Terraform state bucket names)
   - ✅ **GitHub Composite Actions**: Optimized workflows using [GitHub Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action) to eliminate code duplication and improve maintainability across deployment workflows
   - ✅ **Pinned GitHub Actions**: All actions pinned to commit SHAs for supply chain security

4. **Multi-AZ Architecture**
   - ✅ VPC with 3×3 subnet design deployed across 3 availability zones
   - ✅ Network segmentation:
     - Public subnets for ALB (internet-facing load balancer)
     - Private subnets for application servers (no direct internet access)
     - Database subnets for RDS instances (isolated from internet)
   - ✅ Multi-AZ RDS deployment for high availability and automatic failover
   - ✅ NAT Gateways in each AZ for redundant internet access

5. **Security & Compliance**
   - ✅ [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html) with [KMS](https://aws.amazon.com/kms/) encryption (optional, can be disabled for cost savings)
   - ✅ KMS encryption for RDS and CloudWatch Logs (EBS encryption relies on account defaults)
   - ✅ [IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) enforcement on EC2 instances for metadata security
   - ✅ Basic SSL/TLS configuration for database connections
   - ✅ Deletion protection enabled for production RDS and ALB resources

6. **Monitoring & Operations with Governance**
   - ✅ Auto Scaling Groups with simplified configuration
   - ✅ Basic CloudWatch monitoring for database CPU utilization
   - ✅ Automated database backups with environment-specific retention periods
   - ✅ **Comprehensive tagging strategy**: Enforces governance through standardized tags enabling cost attribution, resource filtering by project/product, and custom automation capabilities
   - ✅ Module dependency management with proper resource references

## Enhancement Opportunities (WIP)

- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) integration for enhanced RDS password rotation
- [Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) integration for configuration management (currently using environment-specific tfvars files)
- Explicit EBS encryption configuration (currently relies on account defaults)
- Add Terraform `prevent_destroy` lifecycle rules for critical resources
- Manual approval based workflow for production environment deployment
- ✅ Pin GitHub Actions versions with commit hash rather than tags for enhanced security
- Resolve Checkov skip checks to eliminate security exceptions and improve compliance posture
- Drift detection scheduled jobs for infrastructure compliance monitoring

## Challenges Faced

- OIDC configuration complexity with GitHub trust relationships
  - [GitHub Actions Update on OIDC Integration with AWS](https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/) was helpful
- GitLeaks licensing requirements led to choosing TruffleHog for secrets scanning

## Prerequisites

- Basic knowledge of Terraform, GitHub Actions, and AWS
- Complete setup instructions available in the [bootstrap README](bootstrap/README.md)

## Demo

**Note:** Prerequisites should be set up (i.e., OIDC and IAM role for GitHub Actions to assume in dev account) before running the pipeline.

This section showcases the different stages of the GitHub Actions CI/CD pipeline and the AWS resources created through the Terraform modules.

### Environment Configuration

| Environment | VPC CIDR    | EC2 Type  | RDS Type     | Auto Scaling |
|-------------|-------------|-----------|--------------|-------------|
| Development | 10.0.0.0/16 | t3.micro  | db.t3.micro  | 1-2 (1)     |
| Staging     | 10.1.0.0/16 | t3.small  | db.t3.small  | 2-4 (2)     |
| Production  | 10.2.0.0/16 | m5.large  | db.r5.large  | 3-10 (3)    |

### GitHub Actions Pipeline Stages

- **Pipeline Execution**: The CI/CD pipeline executes through distinct stages as shown below:
  
  <img src="assets/gha.png" alt="GitHub Actions Pipeline Stages" width="800" />
  
  **Fully Automated Sequential Pipeline** triggered on push to main:
  1. **Lint and Scan**: Security and quality checks using Terraform fmt, TFLint static analysis, Checkov, and TruffleHog
  2. **Development**: Automated deployment to dev environment after successful validation
  3. **Staging**: Deployment to staging environment following dev success
  4. **Production**: Deployed automatically after staging succeeds (no manual intervention required)

- **Lint and Scan Stage Details**:
  
  <img src="assets/lint-and-scan stage.png" alt="Lint and Scan Stage" width="800" />
  
  The lint and scan stage provides security and quality gates before any deployment begins.

### AWS Terraform Modules Deployed

- **Simplified Modular Infrastructure**: Streamlined modules with essential features only:
  - **VPC Module**: Networking Infrastructure
  - **ALB Module**: Load Balancing Infrastructure
  - **App Module**: Autoscaling Infrastructure
  - **Database Module**: PostgreSQL

### Infrastructure Resources Created

- **Key AWS Resources**: Created by Terraform modules:
  
  **Application Load Balancer:**
  <img src="assets/alb.png" alt="Application Load Balancer" width="800" />
  
  Internet-facing Application Load Balancer with target groups and health checks integrated with Auto Scaling Groups.
  
  **RDS Database with Tagging:**
  <img src="assets/rds tags.png" alt="RDS Database" width="800" />
  
  Multi-AZ RDS instance with comprehensive tagging strategy for consistent cost allocation and resource management across infrastructure components.

## General Cost Optimization Opportunities in AWS

### 1. Network Costs
- **[VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html#concepts-vpc-endpoints)**: Add S3 and DynamoDB VPC endpoints to eliminate NAT Gateway data transfer costs
- **Single NAT Gateway**: Use one NAT Gateway instead of three for non-production environments
- **CloudWatch Logs Retention**: Set appropriate log retention periods (7 days dev, 30 days staging, 90 days prod)

### 2. Compute Optimization  
- **[Graviton Instances](https://aws.amazon.com/ec2/graviton/)**: Migrate to ARM-based EC2 Graviton servers as they offer cheaper compute costs
- **Scheduled Scaling**: Implement time-based scaling to shut down dev/staging environments during weekends
- **AWS Compute Optimizer**: Use [AWS Compute Optimizer](https://aws.amazon.com/compute-optimizer/) to identify over-provisioned EC2 instances and right-size workloads
- **Simplified Auto Scaling**: Current configuration uses basic auto scaling without complex scaling policies

### 3. Storage Optimization
- **gp3 EBS Volumes**: Upgrade from gp2 to gp3 volumes for better cost-performance ratio
- **EBS Snapshot Lifecycle**: Implement automated snapshot deletion after 30 days for dev, 90 days for staging
- **S3 Storage Tiering**: Implement [S3 Lifecycle policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html) or S3 Intelligent Tiering for application data/logs
- **RDS Storage Autoscaling**: Enable storage autoscaling to avoid over-provisioning

### 4. Database Optimization
- **Reserved Instances**: With predictable, steady-state usage, RDS Reserved Instances can provide savings
- **Backup Retention**: Reduce backup retention to 7 days for dev, 14 days for staging
- **Simplified Configuration**: Removed enhanced monitoring, performance insights, and complex parameter tuning to reduce costs

### 5. Automation & Optimization
- **Lambda Resource Cleanup**: Deploy Lambda functions to automatically identify and delete orphaned resources (unused EIPs, unattached EBS volumes, idle load balancers)
- **Cost Anomaly Detection**: Enable [AWS Cost Anomaly Detection](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/getting-started-ad.html) for automated spending alerts

### 6. Monitoring & Alerting
- **Governance Through Tagging**: Comprehensive standardized tags enable cost allocation by project/product, automated resource management, and compliance tracking
- **Unused Resource Detection**: Regular audits for idle load balancers, unattached EBS volumes
- **Establish FinOps Culture**: Implement cost awareness and optimization practices across teams