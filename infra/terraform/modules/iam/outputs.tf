output "execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN."
  value       = aws_iam_role.task.arn
}

output "deploy_role_arn" {
  description = "Role GitHub Actions assumes via OIDC (set as AWS_ROLE_ARN in the workflow)."
  value       = aws_iam_role.deploy.arn
}
