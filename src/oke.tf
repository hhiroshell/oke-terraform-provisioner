variable "oke_kubernetes_version" {
  default = "v1.15.7"
}

variable "oke_kubernetes_dashboard_enabled" {
  default = false
}

variable "oke_helm_tiller_enabled" {
  default = false
}

variable "oke_kubernetes_node_version" {
  default = "v1.15.7"
}

variable "oke_node_pool_node_image_name" {
  default = "Oracle-Linux-7.6"
}

variable "oke_node_pool_shape" {
  type = list(string)
  default = [
    "VM.Standard.E2.1",
  ]
}

variable "oke_node_pool_quantity" {
  type = list(number)
  default = [
    2,
  ]
}

locals {
  oke_kube_config_expiration    = 2592000
  oke_kube_config_token_version = "2.0.0"
}

resource "oci_containerengine_cluster" "oke-cluster" {
  compartment_id     = var.compartment_ocid
  name               = "${var.oke_resource_prefix}-cluster"
  kubernetes_version = var.oke_kubernetes_version
  vcn_id             = oci_core_virtual_network.oke-vcn.id
  options {
    service_lb_subnet_ids = [
      oci_core_subnet.oke-sn-lb.id,
    ]
    add_ons {
      is_kubernetes_dashboard_enabled = var.oke_kubernetes_dashboard_enabled
      is_tiller_enabled               = var.oke_helm_tiller_enabled
    }
  }
}

resource "oci_containerengine_node_pool" "oke-node-pool" {
  count              = length(var.oke_node_pool_shape)
  cluster_id         = oci_containerengine_cluster.oke-cluster.id
  compartment_id     = var.compartment_ocid
  name               = "${var.oke_resource_prefix}-node-pool-${count.index}"
  kubernetes_version = var.oke_kubernetes_node_version
  node_image_name    = var.oke_node_pool_node_image_name
  node_shape         = element(var.oke_node_pool_shape, count.index)
  node_config_details {
    dynamic "placement_configs" {
      for_each = [for ad in data.oci_identity_availability_domains.ads.availability_domains: {
        name = ad.name
      }]
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = oci_core_subnet.oke-sn-w.id
      }
    }
    size = element(var.oke_node_pool_quantity, count.index)
  }
}

data "oci_containerengine_cluster_kube_config" "oke-kube-config" {
  count         = "${var.on_resource_manager ? 0 : 1}"
  cluster_id    = oci_containerengine_cluster.oke-cluster.id
  expiration    = local.oke_kube_config_expiration
  token_version = local.oke_kube_config_token_version
}

resource "local_file" "kubeconfig" {
  count    = "${var.on_resource_manager ? 0 : 1}"
  content  = data.oci_containerengine_cluster_kube_config.oke-kube-config[count.index].content
  filename = "${path.module}/generated/kubeconfig"
}