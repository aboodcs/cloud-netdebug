# ─────────────────────────────────────────────────────────────────────────────
# Network Security Groups
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_network_security_group" "admin_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-admin-nsg"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}


resource "oci_core_network_security_group" "target_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-target-nsg"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}


# ─────────────────────────────────────────────────────────────────────────────
# Laptop → admin-01
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_network_security_group_security_rule" "admin_allow_ssh_from_laptop" {
  network_security_group_id = oci_core_network_security_group.admin_nsg.id

  direction   = "INGRESS"
  protocol    = "6"
  description = "Allow SSH from operator IP"
  source      = var.allowed_ssh_cidr
  source_type = "CIDR_BLOCK"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

## Allow stateful SSH access from the operator's IP to admin-01 on TCP port 22.
#                    INTERNET
#                       │
#                       │ TCP 22
#                       │ YOUR_IP/32
#                       ▼
#                ┌─────────────┐
#                │ admin_nsg   │
#                └──────┬──────┘
#                       │
#                       ▼
#                    admin-01


# ─────────────────────────────────────────────────────────────────────────────
# admin-01 → target-01
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_network_security_group_security_rule" "admin_allow_ssh_to_target" {
  network_security_group_id = oci_core_network_security_group.admin_nsg.id

  direction        = "EGRESS"
  protocol         = "6"
  description      = "Allow SSH from admin-01 to target-01"
  destination      = oci_core_network_security_group.target_nsg.id
  destination_type = "NETWORK_SECURITY_GROUP"
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}


resource "oci_core_network_security_group_security_rule" "target_allow_ssh_from_admin" {
  network_security_group_id = oci_core_network_security_group.target_nsg.id

  direction   = "INGRESS"
  protocol    = "6"
  description = "Allow SSH from admin-01"
  source      = oci_core_network_security_group.admin_nsg.id
  source_type = "NETWORK_SECURITY_GROUP"
  stateless   = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

## Allow stateful SSH access from admin-01 to target-01 on TCP port 22.
#                    admin-01
#                       │
#                       │ TCP 22
#                       ▼
#                ┌─────────────┐
#                │ admin_nsg   │
#                └──────┬──────┘
#                       │
#                       ▼
#                ┌─────────────┐
#                │ target_nsg  │
#                └──────┬──────┘
#                       │
#                       ▼
#                    target-01


# ─────────────────────────────────────────────────────────────────────────────
# target-01 → Internet: HTTP
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_network_security_group_security_rule" "target_allow_http_to_internet" {
  network_security_group_id = oci_core_network_security_group.target_nsg.id

  direction        = "EGRESS"
  protocol         = "6"
  description      = "Allow HTTP from target-01 to Internet"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

## Allow stateful HTTP access from target-01 to the Internet on TCP port 80.
#                    target-01
#                       │
#                       │ TCP 80
#                       ▼
#                ┌─────────────┐
#                │ target_nsg  │
#                └──────┬──────┘
#                       │
#                       ▼
#                  NAT Gateway
#                       │
#                       ▼
#                    INTERNET


# ─────────────────────────────────────────────────────────────────────────────
# target-01 → Internet: HTTPS
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_network_security_group_security_rule" "target_allow_https_to_internet" {
  network_security_group_id = oci_core_network_security_group.target_nsg.id

  direction        = "EGRESS"
  protocol         = "6"
  description      = "Allow HTTPS from target-01 to Internet"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

## Allow stateful HTTPS access from target-01 to the Internet on TCP port 443.
#                    target-01
#                       │
#                       │ TCP 443
#                       ▼
#                ┌─────────────┐
#                │ target_nsg  │
#                └──────┬──────┘
#                       │
#                       ▼
#                  NAT Gateway
#                       │
#                       ▼
#                    INTERNET


# ─────────────────────────────────────────────────────────────────────────────
# target-01 → OCI Services
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_network_security_group_security_rule" "target_allow_https_to_oci_services" {
  network_security_group_id = oci_core_network_security_group.target_nsg.id

  direction        = "EGRESS"
  protocol         = "6"
  description      = "Allow HTTPS from target-01 to OCI services"
  destination      = data.oci_core_services.all_services.services[0].cidr_block
  destination_type = "SERVICE_CIDR_BLOCK"
  stateless        = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

## Allow stateful HTTPS access from target-01 to OCI services on TCP port 443.
#                    target-01
#                       │
#                       │ TCP 443
#                       ▼
#                ┌─────────────┐
#                │ target_nsg  │
#                └──────┬──────┘
#                       │
#                       ▼
#                Service Gateway
#                       │
#                       ▼
#                  OCI SERVICES


# ─────────────────────────────────────────────────────────────────────────────
# target-01 → admin-01
# ─────────────────────────────────────────────────────────────────────────────

# No security rule is created for target-01 to initiate SSH to admin-01.
#
# The admin-01 → target-01 SSH connection is stateful, so response traffic
# from target-01 back to admin-01 is automatically allowed.
#
#                    admin-01
#                       │
#                       │ SSH connection
#                       ▼
#                    target-01
#                       │
#                       │ Reply traffic
#                       │ automatically allowed
#                       ▼
#                    admin-01