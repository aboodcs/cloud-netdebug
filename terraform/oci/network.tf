resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id

  cidr_blocks  = var.cidr_blocks
  display_name = "${var.project_name}-vcn"
  dns_label    = "netdebug"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-igw"
  enabled      = true

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name  = "${var.project_name}-nat-gateway"
  block_traffic = false

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-sgw"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
    description       = "Route internet traffic through the Internet Gateway"
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
    description       = "Route private traffic through the NAT Gateway"
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
    description       = "Route OCI service traffic through the Service Gateway"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  cidr_block   = var.public_subnet_cidr
  display_name = "${var.project_name}-public-subnet"
  dns_label    = "public"

  route_table_id = oci_core_route_table.public.id

  security_list_ids          = [oci_core_vcn.main.default_security_list_id]
  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_subnet" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  cidr_block   = var.private_subnet_cidr
  display_name = "${var.project_name}-private-subnet"
  dns_label    = "private"

  route_table_id = oci_core_route_table.private.id

  security_list_ids          = [oci_core_vcn.main.default_security_list_id]
  prohibit_public_ip_on_vnic = true

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

## VCN
## ├── Internet Gateway
## ├── NAT Gateway
## ├── Service Gateway
## │
## ├── Public Route Table
## │   └── 0.0.0.0/0 → Internet Gateway
## │
## ├── Private Route Table
## │   ├── 0.0.0.0/0 → NAT Gateway
## │   └── OCI Services → Service Gateway
## │
## ├── Public Subnet → Public Route Table
## └── Private Subnet → Private Route Table