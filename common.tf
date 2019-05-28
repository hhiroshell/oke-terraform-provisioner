# OCI Provier
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

provider "oci" {
    tenancy_ocid = "${var.tenancy_ocid}"
    user_ocid = "${var.user_ocid}"
    fingerprint = "${var.fingerprint}"
    private_key_path = "${var.private_key_path}"
    region = "${var.region}"
}

# Other common variables and references
variable "oke_resource_prefix" {}
variable "compartment_ocid" {}

data "oci_identity_availability_domains" "ads" {
    compartment_id = "${var.tenancy_ocid}"
}