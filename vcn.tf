variable "oke_resource_prefix" {}

resource "oci_core_virtual_network" "oke-vcn" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.oke_resource_prefix}-oke-vcn"
    cidr_block = "10.0.0.0/16"
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
        destination = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.oke-ig.id}"
    }
}

resource "oci_core_security_list" "oke-sl-lb" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-lb"
    egress_security_rules = [
        {
            stateless = true
            destination = "0.0.0.0/0"
            protocol = "6"
        }
    ]
    ingress_security_rules = [
        {
            stateless = true
            source = "0.0.0.0/0"
            protocol = "6"
        }
    ]
}

resource "oci_core_security_list" "oke-sl-w" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sl-w"
    egress_security_rules = [
        {
            stateless = true
            destination = "10.0.10.0/24"
            protocol = "all"
        },{
            stateless = true
            destination = "10.0.11.0/24"
            protocol = "all"
        },{
            stateless = true
            destination = "10.0.12.0/24"
            protocol = "all"
        },{
            stateless = false
            destination = "0.0.0.0/0"
            protocol = "all"
        }
    ]
    ingress_security_rules = [
        {
            stateless = true
            source = "10.0.10.0/24"
            protocol = "all"
        },{
            stateless = true
            source = "10.0.11.0/24"
            protocol = "all"
        },{
            stateless = true
            source = "10.0.12.0/24"
            protocol = "all"
        },{
            stateless = false
            source = "0.0.0.0/0"
            protocol = "1"
            icmp_options {
                type = "3"
                code = "4"
            }
        },{
            stateless = false
            source = "130.35.0.0/16"
            protocol = "6"
            tcp_options {
                max = "22"
                min = "22"
            }
        },{
            stateless = false
            source = "138.1.0.0/17"
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
        # },{
        #     stateless = false
        #     source = "0.0.0.0/0"
        #     protocol = "6"
        #     tcp_options {
        #         max = "32767"
        #         min = "30000"
        #     }
        }
    ]
}

resource "oci_core_subnet" "oke-sn-lb-ad1" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-lb-ad1"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
    cidr_block = "10.0.20.0/24"
    security_list_ids = ["${oci_core_security_list.oke-sl-lb.id}"]
    dns_label = "lb1"
}

resource "oci_core_subnet" "oke-sn-lb-ad2" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-lb-ad2"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[1], "name")}"
    cidr_block = "10.0.21.0/24"
    security_list_ids = ["${oci_core_security_list.oke-sl-lb.id}"]
    dns_label = "lb2"
}

resource "oci_core_subnet" "oke-sn-w-ad1" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-w-ad1"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[0], "name")}"
    cidr_block = "10.0.10.0/24"
    security_list_ids = ["${oci_core_security_list.oke-sl-w.id}"]
    dns_label = "w1"
}

resource "oci_core_subnet" "oke-sn-w-ad2" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-w-ad2"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[1], "name")}"
    cidr_block = "10.0.11.0/24"
    security_list_ids = ["${oci_core_security_list.oke-sl-w.id}"]
    dns_label = "w2"
}

resource "oci_core_subnet" "oke-sn-w-ad3" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.oke-vcn.id}"
    display_name = "${var.oke_resource_prefix}-oke-sn-w-ad3"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[2], "name")}"
    cidr_block = "10.0.12.0/24"
    security_list_ids = ["${oci_core_security_list.oke-sl-w.id}"]
    dns_label = "w3"
}
