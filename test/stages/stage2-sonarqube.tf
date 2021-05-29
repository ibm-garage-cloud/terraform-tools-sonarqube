module "dev_tools_sonarqube" {
  source = "./module"

  cluster_config_file      = module.dev_cluster.config_file_path
  cluster_type             = module.dev_cluster.platform.type_code
  cluster_ingress_hostname = module.dev_cluster.platform.ingress
  tls_secret_name          = module.dev_cluster.platform.tls_secret
  releases_namespace       = module.dev_capture_state.namespace
  service_account_name     = "sonarqube"
  postgresql               = {
    external      = false
    username      = ""
    password      = ""
    hostname      = ""
    port          = ""
    database_name = ""
  }
}

resource "null_resource" "print_password" {
  depends_on = [module.dev_tools_namespace.admin_password]

  provisioner "local-exec" {
    command = "echo 'Admin password: ${module.dev_tools_sonarqube.admin_password}'"
  }

  provisioner "local-exec" {
    command = "curl -u admin:${module.dev_tools_sonarqube.admin_password} -L ${module.dev_tools_sonarqube.ingress_url}/api/user_tokens/search"

    environment = {
      KUBECONFIG = module.dev_cluster.config_file_path
    }
  }
}
