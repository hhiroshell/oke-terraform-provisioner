locals {
  cidr_public_internet  = "0.0.0.0/0"
  cidr_cluster_wide     = "10.0.0.0/16"
  cidr_vcn_loadbalancer = "10.0.20.0/24"
  cidr_vcn_worker = [
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24",
  ]
}

resource "oci_core_virtual_network" "oke-vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.oke_resource_prefix}-oke-vcn"
  cidr_block     = local.cidr_cluster_wide
  dns_label      = var.oke_resource_prefix
}

resource "oci_core_internet_gateway" "oke-igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-igw"
}

resource "oci_core_nat_gateway" "oke-ngw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-ngw"
}

resource "oci_core_route_table" "oke-rt-igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-rt-igw"
  route_rules {
    destination       = local.cidr_public_internet
    network_entity_id = oci_core_internet_gateway.oke-igw.id
  }
}

resource "oci_core_route_table" "oke-rt-ngw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-rt-ngw"
  route_rules {
    destination       = local.cidr_public_internet
    network_entity_id = oci_core_nat_gateway.oke-ngw.id
  }
}

resource "oci_core_security_list" "oke-sl-lb-public-access" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-sl-lb-public-access"
  egress_security_rules {
    stateless   = true
    destination = local.cidr_public_internet
    protocol    = "6"
  }
  ingress_security_rules {
    stateless = true
    source    = local.cidr_public_internet
    protocol  = "6"
  }
}

resource "oci_core_security_list" "oke-sl-w-between-workers" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
  display_name = "${var.oke_resource_prefix}-oke-sl-w-between-workers"
  dynamic "egress_security_rules" {
    for_each = local.cidr_vcn_worker
    content {
      stateless = true
      destination = egress_security_rules.value
      protocol = "all"
    }
  }
  dynamic "ingress_security_rules" {
    for_each = local.cidr_vcn_worker
    content {
      stateless = true
      source = ingress_security_rules.value
      protocol = "all"
    }
  }
}

resource "oci_core_security_list" "oke-sl-w-to-external-services" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-sl-w-to-external-services"
  egress_security_rules {
    stateless   = false
    destination = local.cidr_public_internet
    protocol    = "all"
  }
}

resource "oci_core_security_list" "oke-sl-w-optional" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke-vcn.id
  display_name   = "${var.oke_resource_prefix}-oke-sl-w-optional"
  ingress_security_rules {
    stateless = false
    source    = local.cidr_cluster_wide
    protocol  = "6"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    stateless = false
    source    = local.cidr_cluster_wide
    protocol  = "6"
    tcp_options {
      max = "32767"
      min = "30000"
    }
  }
}

resource "oci_core_subnet" "oke-sn-lb" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.oke-vcn.id
  display_name               = "${var.oke_resource_prefix}-oke-sn-lb"
  cidr_block                 = local.cidr_vcn_loadbalancer
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke-rt-igw.id
  security_list_ids = [
    oci_core_security_list.oke-sl-lb-public-access.id,
  ]
  dns_label = "lb"
}

resource "oci_core_subnet" "oke-sn-w" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.oke-vcn.id
  display_name               = "${var.oke_resource_prefix}-oke-sn-w"
  cidr_block                 = local.cidr_vcn_worker[0]
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.oke-rt-ngw.id
  security_list_ids = [
    oci_core_security_list.oke-sl-w-to-external-services.id,
    oci_core_security_list.oke-sl-w-between-workers.id,
    # oci_core_security_list.oke-sl-w-optional.id,
  ]
  dns_label = "w"
}