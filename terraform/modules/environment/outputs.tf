output "environment" {
  value       = github_repository_environment.this
  description = "Repository environment resource"
}

output "deployment_policies" {
  value       = github_repository_environment_deployment_policy.this
  description = "Deployment branch policy resources by branch pattern"
}

output "variables" {
  value       = github_actions_environment_variable.this
  description = "Environment variable resources by name"
}

output "secrets" {
  value       = { for name, secret in github_actions_environment_secret.this : name => secret.id }
  description = "Environment secret resource IDs by name"
}
