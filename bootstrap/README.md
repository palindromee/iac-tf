# Bootstrap Setup Guide

This directory contains the initial setup configuration for the AWS Multi-Tier Infrastructure Platform, focusing on secure GitHub Actions integration using OIDC and centralized Terraform state management.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [OIDC Setup Process](#oidc-setup-process)
3. [Terraform State Setup](#terraform-state-setup)
4. [Security Considerations](#security-considerations)
5. [Validation & Troubleshooting](#validation--troubleshooting)
6. [Next Steps](#next-steps)

## Prerequisites

### AWS Account Setup

1. **AWS CLI Configuration**
   ```bash
   aws configure
   ```

2. **Required AWS Accounts**
   - Tooling account (for centralized state management) - **Setup first**
   - Development account
   - Staging account  
   - Production account

### GitHub Repository Setup

1. **Fork or Clone Repository**
2. **Create GitHub Environments** (optional for enhanced security):
   - `development`
   - `staging` 
   - `production`

## OIDC Setup Process

The OIDC setup creates both the OIDC provider and IAM role needed for GitHub Actions to securely authenticate with AWS.

### Deployment Options

**Option 1: Terraform (Recommended)**

1. Navigate to environment bootstrap directory for each account
2. Initialize and apply Terraform configuration
3. Provide the required parameters:
   - `environment`: Environment name (dev/staging/prod)
   - `github_org`: Your GitHub organization or username  
   - `github_repo`: Your repository name
   - `tooling_account_id`: Account ID for centralized state storage

**Option 2: Manual Configuration**

Create OIDC provider and IAM roles manually in AWS Console following the same trust relationships and permissions as the Terraform modules.

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `environment` | Environment name | `dev` |
| `github_org` | GitHub organization or username | `mycompany` |
| `github_repo` | Repository name | `aws-infrastructure` |
| `tooling_account_id` | Tooling account for state storage | `123456789012` |

## Terraform State Setup

### Why Remote State Storage?

By default, Terraform stores state locally in a file named `terraform.tfstate`. For team collaboration, [remote state storage](https://developer.hashicorp.com/terraform/language/state/remote) is essential because:

- **Team Collaboration**: Shared state enables multiple team members to work on the same infrastructure
- **State Locking**: Prevents concurrent runs that could corrupt state or cause conflicts
- **Centralized Management**: Single source of truth for infrastructure state across environments
- **Data Sharing**: Allows teams to share infrastructure outputs between configurations
- **Backup and Versioning**: Remote backends provide built-in backup and state history

### S3 Backend Implementation

This project uses [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) for remote state storage in a centralized tooling account.

**Setup Order (Important):**
1. **First**: Set up tooling account infrastructure:
   ```bash
   cd bootstrap/tooling
   terraform init
   terraform apply
   ```
2. **Then**: Configure environment-specific OIDC in each account using the tooling account outputs

**Key Infrastructure Components:**
- **S3 Bucket**: Centralized state storage with versioning and encryption
- **KMS Key**: Customer-managed encryption for state files
- **Bucket Policy**: Cross-account access for environment accounts
- **Public Access Block**: Prevents accidental public exposure

**S3 State Files Organization:**
<img src="../assets/s3 state file.png" alt="S3 State Files" width="800" />

**Detailed State File Structure:**
<img src="../assets/s3 statefiles 2.png" alt="S3 State Files Detail View" width="800" />

Centralized state management with environment and layer isolation for secure, scalable infrastructure deployment.

## Security Considerations

### Why OIDC Instead of IAM Keys?

- **No Long-lived Credentials**: OIDC tokens are temporary (1 hour max)
- **Least Privilege**: Roles can be scoped to specific repositories and branches
- **Auditable**: CloudTrail logs show exactly which GitHub workflow assumed which role
- **Revocable**: Disable the OIDC provider to immediately revoke all access

### IAM Role Permissions

The bootstrap creates roles with permissions for:
- Terraform state operations (S3 and KMS)
- VPC and networking resources
- Load balancer operations
- EC2 and Auto Scaling management
- RDS database operations
- Limited IAM permissions for instance profiles

### Trust Relationship

Roles trust your specific GitHub organization/repository with branch-level access controls.

## Validation & Troubleshooting

**Test Setup:** Push a change to trigger workflow and verify no authentication errors in GitHub Actions logs.

**Common Issues:**
- **Trust Relationship Errors**: Verify GitHub org/user and repository name
- **Permission Denied**: Review IAM policies and CloudTrail logs
- **Role ARN Not Found**: Confirm bootstrap applied successfully

## Next Steps

After completing the bootstrap setup:

### Configure GitHub Secrets

Add these repository secrets:
- `AWS_DEV_ROLE_ARN`, `AWS_STAGING_ROLE_ARN`, `AWS_PROD_ROLE_ARN`: Role ARNs from bootstrap outputs
- `TF_STATE_BUCKET`: S3 bucket name from tooling account
- `AWS_REGION`: Deployment region (optional, defaults to us-east-1)

### Deploy Infrastructure

1. Update `terraform.tfvars` files in `environments/dev/`, `environments/staging/`, and `environments/prod/` directories
2. Test deployment starting with development environment
3. View pipeline results in the main README [Demo section](../README.md#demo)