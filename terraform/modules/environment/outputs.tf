output "environment" {
  value       = github_repository_environment.this
  description = "Repository environment resource"
}

output "deployment_policies" {
  value       = github_repository_environment_deployment_policy.this
  description = "Deployment branch policy resources by branch pattern"
}
