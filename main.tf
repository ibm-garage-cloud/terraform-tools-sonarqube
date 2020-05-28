provider "helm" {
  version = ">= 1.1.1"

  kubernetes {
    config_path = var.cluster_config_file
  }
}

provider "null" {
}

locals {
  tmp_dir      = "${path.cwd}/.tmp"
  ingress_host = "${var.hostname}-${var.releases_namespace}.${var.cluster_ingress_hostname}"
  ingress_url  = "https://${local.ingress_host}"
  secret_name  = "sonarqube-access"
  config_name  = "sonarqube-config"
  plugin_value = "{${join(",", var.plugins)}}"
  settings     = var.postgresql.external ? [{
    name  = "postgresql.enabled"
    value = "false"
  }, {
    name  = "postgresql.postgresqlServer"
    value = var.postgresql.hostname
  }, {
    name  = "postgresql.postgresqlDatabase"
    value = var.postgresql.database_name
  }, {
    name  = "postgresql.postgresqlUsername"
    value = var.postgresql.username
  }, {
    name  = "postgresql.postgresqlPassword"
    value = var.postgresql.password
  }, {
    name  = "postgresql.service.port"
    value = var.postgresql.port
  }] : []
}

resource "helm_release" "sonarqube" {
  name         = "sonarqube"
  repository   = "https://oteemo.github.io/charts"
  chart        = "sonarqube"
  version      = var.helm_version
  namespace    = var.releases_namespace
  timeout      = 1200
  force_update = true
  replace      = true
  wait         = false

  values = [
    file("${path.module}/sonarqube-values.yaml")
  ]

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "postgresql.persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "ingress.hosts[0].name"
    value = local.ingress_host
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = var.tls_secret_name
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = local.ingress_host
  }

  set {
    name  = "ingress.enabled"
    value = var.cluster_type == "kubernetes" ? "true" : "false"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "postgresql.serviceAccount.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.serviceAccount.name"
    value = "sonarqube"
  }

//  set {
//    name  = "postgresql.volumePermissions.enabled"
//    value = var.cluster_type == "kubernetes" ? "false" : "true"
//  }

//  set {
//    name  = "plugins.install"
//    value = local.plugin_value
//  }

  dynamic "set" {
    for_each = local.settings
    content {
      name  = set.value["name"]
      value = set.value["value"]
    }
  }
}

resource "null_resource" "sonarqube_route" {
  depends_on = [helm_release.sonarqube]
  count      = var.cluster_type != "kubernetes" ? 1 : 0

  triggers = {
    kubeconfig = var.cluster_config_file
    namespace  = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-route.sh ${self.triggers.namespace} sonarqube-sonarqube sonarqube"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/delete-reoute.sh ${self.triggers.namespace} sonarqube"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource "helm_release" "sonarqube-config" {
  depends_on = [null_resource.sonarqube_route]

  name         = "sonarqube-config"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "tool-config"
  namespace    = var.releases_namespace
  force_update = true

  set {
    name  = "name"
    value = "sonarqube"
  }

  set {
    name  = "url"
    value = local.ingress_url
  }

  set {
    name  = "username"
    value = "admin"
  }

  set {
    name  = "password"
    value = "admin"
  }
}

resource "null_resource" "wait-for-sonarqube" {
  depends_on = [helm_release.sonarqube]

  provisioner "local-exec" {
    command = "kubectl rollout status deployment/sonarqube-sonarqube -n ${var.releases_namespace}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}
