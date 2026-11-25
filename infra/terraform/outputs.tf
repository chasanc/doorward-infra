output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by stage (qa, prod)."
  value       = module.ecr.repository_urls
}
