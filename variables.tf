
variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "releases_namespace" {
  type        = string
  description = "Name of the existing namespace where the Helm Releases will be deployed."
}

variable "cluster_ingress_hostname" {
  type        = string
  description = "Ingress hostname of the IKS cluster."
}

variable "hostname" {
  type        = string
  description = "The hostname that will be used for the ingress/route"
  default     = "sonarqube"
}

variable "cluster_type" {
  description = "The cluster type (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "helm_version" {
  description = "The version of the helm chart that should be used"
  type        = string
  default     = "6.4.1"
}

variable "service_account_name" {
  description = "The name of the service account that should be used for the deployment"
  type        = string
  default     = "sonarqube-sonarqube"
}

variable "plugins" {
  description = "The list of plugins that will be installed on SonarQube"
  type        = list(string)
  default     = [
    "https://github.com/checkstyle/sonar-checkstyle/releases/download/4.33/checkstyle-sonar-plugin-4.33.jar"
  ]
}

variable "tls_secret_name" {
  type        = string
  description = "The secret containing the tls certificates"
  default = ""
}

variable "volume_capacity" {
  type        = string
  description = "The volume capacity of the persistence volume claim"
  default     = "2Gi"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the persistence volume claim"
  default     = "ibmc-file-gold"
}

variable "postgresql" {
  type = object({
    username      = string
    password      = string
    hostname      = string
    port          = string
    database_name = string
    external      = bool
  })
  description = "Properties for an existing postgresql database"
  default     = {
    username      = ""
    password      = ""
    hostname      = ""
    port          = ""
    database_name = ""
    external      = false
  }
}

variable "gitops_dir" {
  type        = string
  description = "Directory where the gitops repo content should be written"
  default     = ""
}

variable "mode" {
  type        = string
  description = "The mode of operation for the module (setup)"
  default     = ""
}
