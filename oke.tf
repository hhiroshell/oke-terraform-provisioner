variable "oke_cluster_name" {}
variable "oke_kubernetes_version" { default = "v1.11.5" }
variable "oke_kubernetes_dashboard_enabled" { default = true }
variable "oke_helm_tiller_enabled" { default = false }

variable "oke_node_pool_name" {}
variable "oke_kubernetes_node_version" { default = "v1.11.5" }
variable "oke_node_pool_node_image_name" { default = "Oracle-Linux-7.5" }
variable "oke_node_pool_shape" { default = "VM.Standard1.1" }
variable "oke_node_pool_quantity_per_subnet" { default = 1 }
variable "oke_kube_config_expiration" { default = 2592000 }
variable "oke_kube_config_token_version" { default = "1.0.0" }

resource "oci_containerengine_cluster" "oke-cluster" {
    compartment_id = "${var.compartment_ocid}"
    kubernetes_version = "${var.oke_kubernetes_version}"
    name = "${var.oke_cluster_name}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    options {
        service_lb_subnet_ids = [
            "${oci_core_subnet.oke-sn-lb-ad1.id}",
            "${oci_core_subnet.oke-sn-lb-ad2.id}"
        ]
        add_ons {
            is_kubernetes_dashboard_enabled = "${var.oke_kubernetes_dashboard_enabled}"
            is_tiller_enabled = "${var.oke_helm_tiller_enabled}"
        }
    }
}

resource "oci_containerengine_node_pool" "oke-node-pool" {
    cluster_id = "${oci_containerengine_cluster.oke-cluster.id}"
    compartment_id = "${var.compartment_ocid}"
    kubernetes_version = "${var.oke_kubernetes_node_version}"
    name = "${var.oke_node_pool_name}"
    node_image_name = "${var.oke_node_pool_node_image_name}"
    node_shape = "${var.oke_node_pool_shape}"
    subnet_ids = [
        "${oci_core_subnet.oke-sn-w-ad1.id}",
        "${oci_core_subnet.oke-sn-w-ad2.id}",
        "${oci_core_subnet.oke-sn-w-ad3.id}"
    ]
    quantity_per_subnet = "${var.oke_node_pool_quantity_per_subnet}"
}

data "oci_containerengine_cluster_kube_config" "oke-kube-config" {
    cluster_id = "${oci_containerengine_cluster.oke-cluster.id}"
    expiration = "${var.oke_kube_config_expiration}"
    token_version = "${var.oke_kube_config_token_version}"
}

resource "local_file" "kubeconfig" {
    content = "${data.oci_containerengine_cluster_kube_config.oke-kube-config.content}"
    filename = "${path.module}/generated/kubeconfig"
}
