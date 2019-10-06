/* 
 * Provider for the OCI (Oracle Cloud Infrastructre).
 * This file have to be removed form template archives for OCI Resource Manager.
 */
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
