resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name          = "${var.project_name}-vpc"
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name          = "${var.project_name}-igw"
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

## ─── Elastic IP for NAT Gateway ──────────────────────────────────────────────

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name          = "${var.project_name}-nat-eip"
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

## ─── NAT Gateway ─────────────────────────────────────────────────────────────

resource "aws_nat_gateway" "main" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat.id
  depends_on    = [aws_internet_gateway.main]
  tags = {
    Name          = "${var.project_name}-nat-gateway"
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name          = "${var.project_name}-public-route-table"
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id

  }
  tags = {
    Name          = "${var.project_name}-private-route-table"
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


# VPC
# ├── Internet Gateway
# ├── Public Subnet
# │   └── Public Route Table
# │       └── 0.0.0.0/0 → IGW
# │
# ├── NAT Gateway
# │   ├── inside Public Subnet
# │   └── Elastic IP
# │
# └── Private Subnet
#     └── Private Route Table
#         └── 0.0.0.0/0 → NAT Gateway