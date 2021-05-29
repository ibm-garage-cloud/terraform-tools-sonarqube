output "ingress_host" {
  description = "The ingress host for the SonarQube instance"
  value       = local.ingress_host
  depends_on  = [helm_release.sonarqube]
}

output "ingress_url" {
  description = "The ingress url for the SonarQube instance"
  value       = local.ingress_url
  depends_on  = [helm_release.sonarqube]
}

output "config_name" {
  description = "The name of the configmap created to store the url"
  value       = local.config_name
  depends_on  = [helm_release.sonarqube]
}

output "secret_name" {
  description = "The name of the secret created to store the credentials"
  value       = local.secret_name
  depends_on  = [helm_release.sonarqube]
}

output "service_account" {
  description = "The service account name that was used"
  value       = var.service_account_name
  depends_on  = [helm_release.sonarqube]
}

output "namespace" {
  description = "The namespace where sonarqube has been installed"
  value       = var.releases_namespace
  depends_on  = [helm_release.sonarqube]
}

output "admin_password" {
  description = "The admin password that was generated"
  value       = random_password.admin_password.result
  depends_on  = [helm_release.sonarqube]
  sensitive   = true
}
