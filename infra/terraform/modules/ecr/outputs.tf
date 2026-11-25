output "repository_urls" {
  description = "Repository URLs keyed by stage (qa, prod)."
  value       = { for stage, repo in aws_ecr_repository.this : stage => repo.repository_url }
}
