variable "oke_resource_prefix" {}

locals {
    cidr_public_internet = "0.0.0.0/0"
    cidr_cluster_wide = "10.0.0.0/16"
    cidr_vcn_loadbalancer_ad1 = "10.0.20.0/24"
    cidr_vcn_loadbalancer_ad2 = "10.0.21.0/24"
    cidr_vcn_worker_ad1 = "10.0.10.0/24"
    cidr_vcn_worker_ad2 = "10.0.11.0/24"
    cidr_vcn_worker_ad3 = "10.0.12.0/24"
}

resource "oci_core_virtual_network" "oke-vcn" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.oke_resource_prefix}-oke-vcn"
    cidr_block = "${local.cidr_cluster_wide}"
    dns_label = "${var.oke_resource_prefix}"
}

resource "oci_core_internet_gateway" "oke-ig" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-ig"
}

resource "oci_core_default_route_table" "oke-df-rt" {
    manage_default_resource_id = "${oci_core_virtual_network.oke-vcn.default_route_table_id}"
    display_name = "${var.oke_resource_prefix}-oke-df-rt"
    route_rules {
        destination = "${local.cidr_public_internet}"
        network_entity_id = "${oci_core_internet_gateway.oke-ig.id}"
    }
}

resource "oci_core_security_list" "oke-sl-lb-from-internet" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-lb-from-internet"
    ingress_security_rules = [
        {
            stateless = false
            source = "${local.cidr_public_internet}"
            protocol = "6"
            tcp_options {
                max = "80"
                min = "80"
            }
        },{
            stateless = false
            source = "${local.cidr_public_internet}"
            protocol = "6"
            tcp_options {
                max = "443"
                min = "443"
            }
        }
    ]
}

resource "oci_core_security_list" "oke-sl-w-between-workers" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-w-between-workers"
    egress_security_rules = [
        {
            stateless = true
            destination = "${local.cidr_vcn_worker_ad1}"
            protocol = "all"
        },{
            stateless = true
            destination = "${local.cidr_vcn_worker_ad2}"
            protocol = "all"
        },{
            stateless = true
            destination = "${local.cidr_vcn_worker_ad3}"
            protocol = "all"
        }
    ]
    ingress_security_rules = [
        {
            stateless = true
            source = "${local.cidr_vcn_worker_ad1}"
            protocol = "all"
        },{
            stateless = true
            source = "${local.cidr_vcn_worker_ad2}"
            protocol = "all"
        },{
            stateless = true
            source = "${local.cidr_vcn_worker_ad3}"
            protocol = "all"
        }
    ]
}

resource "oci_core_security_list" "oke-sl-w-to-external-services" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-w-to-external-services"
    egress_security_rules = [
        {
            stateless = false
            destination = "${local.cidr_public_internet}"
            protocol = "all"
        }
    ]
}

resource "oci_core_security_list" "oke-sl-w-healthcheck-from-master" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-w-healthcheck-from-master"
    ingress_security_rules = [
        {
            stateless = false
            source = "130.35.0.0/16"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "134.70.0.0/17"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "138.1.0.0/16"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "140.91.0.0/17"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "147.154.0.0/16"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "192.29.0.0/16"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        }
    ]
}

resource "oci_core_security_list" "oke-sl-w-optional" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-w-optional"
    ingress_security_rules = [
        {
            stateless = false
            source = "${local.cidr_public_internet}"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "${local.cidr_public_internet}"
            protocol = "6"
            tcp_options {
                max = "32767"
                min = "30000"
            }
        }
    ]
}

resource "oci_core_subnet" "oke-sn-lb-ad1" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-lb-ad1"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
    cidr_block = "10.0.20.0/24"
    security_list_ids = [
        "${oci_core_security_list.oke-sl-lb-from-internet.id}"
    ]
    dns_label = "lb1"
}

resource "oci_core_subnet" "oke-sn-lb-ad2" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-lb-ad2"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[1], "name")}"
    cidr_block = "10.0.21.0/24"
    security_list_ids = [
        "${oci_core_security_list.oke-sl-lb-from-internet.id}"
    ]
    dns_label = "lb2"
}

resource "oci_core_subnet" "oke-sn-w-ad1" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-w-ad1"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
    cidr_block = "${local.cidr_vcn_worker_ad1}"
    security_list_ids = [
        "${oci_core_security_list.oke-sl-w-between-workers.id}",
        "${oci_core_security_list.oke-sl-w-to-external-services.id}",
        "${oci_core_security_list.oke-sl-w-healthcheck-from-master.id}",
        # "${oci_core_security_list.oke-sl-w-optional.id}",
    ]
    dns_label = "w1"
}

resource "oci_core_subnet" "oke-sn-w-ad2" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-w-ad2"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[1], "name")}"
    cidr_block = "${local.cidr_vcn_worker_ad2}"
    security_list_ids = [
        "${oci_core_security_list.oke-sl-w-between-workers.id}",
        "${oci_core_security_list.oke-sl-w-to-external-services.id}",
        "${oci_core_security_list.oke-sl-w-healthcheck-from-master.id}",
        # "${oci_core_security_list.oke-sl-w-optional.id}",
    ]
    dns_label = "w2"
}

resource "oci_core_subnet" "oke-sn-w-ad3" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-w-ad3"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[2], "name")}"
    cidr_block = "${local.cidr_vcn_worker_ad3}"
    security_list_ids = [
        "${oci_core_security_list.oke-sl-w-between-workers.id}",
        "${oci_core_security_list.oke-sl-w-to-external-services.id}",
        "${oci_core_security_list.oke-sl-w-healthcheck-from-master.id}",
        # "${oci_core_security_list.oke-sl-w-optional.id}",
    ]
    dns_label = "w3"
}
