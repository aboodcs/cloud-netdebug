# ─── admin-01 ─────────────────────────────────────────────────────────────

resource "oci_core_instance" "admin_01" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id

  display_name = "${var.project_name}-admin-01"
  shape        = var.instance_shape

  shape_config {
    ocpus         = 1
    memory_in_gbs = 8
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "${var.project_name}-admin-01-vnic"

    nsg_ids = [
      oci_core_network_security_group.admin_nsg.id
    ]
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

#          Laptop
#             │
#             │ SSH :22
#             ▼
#          Internet
#             │
#             ▼
#          Public Subnet
#             │
#             ▼
#     ┌───────────────────────┐
#     │       admin-01        │
#     │                       │
#     │ Private IP: automatic │
#     │ Public IP: yes        │
#     │ Linux: Oracle Linux   │
#     │ NSG: admin_nsg        │
#     └───────────────────────┘


# ─── target-01 ─────────────────────────────────────────────────────────────
resource "oci_core_instance" "target_01" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id

  display_name = "${var.project_name}-target-01"
  shape        = var.instance_shape
  shape_config {
    ocpus         = 1
    memory_in_gbs = 8
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    display_name     = "${var.project_name}-target-01-vnic"

    nsg_ids = [
      oci_core_network_security_group.target_nsg.id
    ]
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}