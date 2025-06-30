output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

# DynamoDB outputs removed - using S3 native locking
# S3 backend now supports native locking without DynamoDB

output "kms_key_id" {
  description = "ID of the KMS key for encryption"
  value       = aws_kms_key.terraform_state.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = aws_kms_key.terraform_state.arn
}

output "kms_alias_name" {
  description = "Name of the KMS key alias"
  value       = aws_kms_alias.terraform_state.name
}

output "tooling_account_id" {
  description = "AWS account ID where the state bucket is hosted"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region where resources are created"
  value       = data.aws_region.current.name
}