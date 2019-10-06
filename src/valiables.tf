# OCI Provier
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

# Other common variables and references
variable "oke_resource_prefix" {
  default = "example"
}

variable "on_resource_manager" {
  default = true
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}