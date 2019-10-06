# OCI Provier
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

# Other common variables and references
variable "oke_resource_prefix" {
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}