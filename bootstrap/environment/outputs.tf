output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "environment_account_id" {
  description = "AWS account ID for this environment"
  value       = data.aws_caller_identity.current.account_id
}

output "sample_workflow_step" {
  description = "Sample GitHub Actions step configuration"
  value       = <<-EOT
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${aws_iam_role.github_actions.arn}
        aws-region: ${data.aws_region.current.name}
        role-session-name: GitHubActions-${var.environment}
  EOT
}