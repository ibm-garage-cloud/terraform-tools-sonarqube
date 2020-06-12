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

resource "local_file" "sonarqube-values" {
  content  = yamlencode({
    image = {
      pullPolicy = "Always"
    }
    persistence = {
      enabled = false
      storageClass = var.storage_class
    }
    serviceAccount = {
      create = true
      name = var.service_account_name
    }
    postgresql = {
      enabled = !var.postgresql.external
      postgresqlServer = var.postgresql.external ? var.postgresql.hostname : ""
      postgresqlDatabase = var.postgresql.external ? var.postgresql.database_name : "sonarDB"
      postgresqlUsername = var.postgresql.external ? var.postgresql.username : "sonarUser"
      postgresqlPassword = var.postgresql.external ? var.postgresql.password : "sonarPass"
      service = {
        port = var.postgresql.external ? var.postgresql.port : 5432
      }
      serviceAccount = {
        enabled = true
        name = var.service_account_name
      }
      persistence = {
        enabled = false
        storageClass = var.storage_class
      }
      volumePermissions = {
        enabled = false
      }
    }
    ingress = {
      enabled = var.cluster_type == "kubernetes"
      annotations = {
        "kubernetes.io/ingress.class" = "nginx"
        "nginx.ingress.kubernetes.io/proxy-body-size" = "20m"
        "ingress.kubernetes.io/proxy-body-size" = "20M"
        "ingress.bluemix.net/client-max-body-size" = "20m"
      }
      hosts = [{
        name = local.ingress_host
      }]
      tls = [{
        secretName = var.tls_secret_name
        hosts = [
          local.ingress_host
        ]
      }]
    }
    plugins = {
      install = var.plugins
    }
    enableTests = false
  })
  filename = "${path.cwd}/.tmp/sonarqube-values.yaml"
}

data "local_file" "sonarqube-values" {
  filename = local_file.sonarqube-values.filename
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
    data.local_file.sonarqube-values.content
  ]
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
    command = "${path.module}/scripts/delete-route.sh ${self.triggers.namespace} sonarqube"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=sonarqube || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "sonarqube-config" {
  depends_on = [null_resource.sonarqube_route, null_resource.delete-consolelink]

  name         = "sonarqube-config"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "tool-config"
  namespace    = var.releases_namespace
  force_update = true

  set {
    name  = "name"
    value = "SonarQube"
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

  set {
    name  = "applicationMenu"
    value = var.cluster_type != "kubernetes"
  }

  set {
    name  = "ingressSubdomain"
    value = var.cluster_ingress_hostname
  }
}

resource "null_resource" "wait-for-sonarqube" {
  depends_on = [helm_release.sonarqube]

  provisioner "local-exec" {
    command = "kubectl rollout status deployment/sonarqube-sonarqube -n ${var.releases_namespace} --timeout=30m"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}
