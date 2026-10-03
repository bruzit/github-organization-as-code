output "repository" {
  value       = github_repository.this
  description = "Repository resource"
}

output "environments" {
  value       = module.environment
  description = "Environment module outputs by environment name"
}
