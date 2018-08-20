# OCI
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}

# General
variable "oke_resource_prefix" {}

# Resources
variable "oke_cluster_name" {}
variable "oke_kubernetes_version" { default = "v1.11.1" }
variable "oke_kubernetes_dashboard_enabled" { default = true }
variable "oke_helm_tiller_enabled" { default = false }
variable "oke_node_pool_name" {}
variable "oke_kubernetes_node_version" { default = "v1.11.1" }
variable "oke_node_pool_node_image_name" { default = "Oracle-Linux-7.5" }
variable "oke_node_pool_shape" { default = "VM.Standard1.1" }
variable "oke_node_pool_quantity_per_subnet" { default = 1 }
variable "oke_kube_config_expiration" { default = 2592000 }
variable "oke_kube_config_token_version" { default = "1.0.0" }
