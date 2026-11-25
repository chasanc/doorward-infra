output "ecr_repository_url" {
  description = "ECR repository URL for this stage."
  value       = module.ecr.repository_url
}

output "deploy_role_arn" {
  description = "Role GitHub Actions assumes via OIDC."
  value       = module.iam.deploy_role_arn
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs_service.cluster_name
}

output "service_name" {
  description = "ECS service name."
  value       = module.ecs_service.service_name
}
