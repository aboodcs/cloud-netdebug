# ─────────────────────────────────────────────────────────────────────────────
# Network Security Groups
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "admin_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.project_name}-admin-sg"

  tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "aws_security_group" "target_sg" {
  vpc_id = aws_vpc.main.id

  name = "${var.project_name}-target-sg"

  tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

# ---------------------------------------------------------
# Laptop -> admin-01
# INBOUND SSH
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "admin_allow_ssh_from_laptop" {
  security_group_id = aws_security_group.admin_sg.id

  cidr_ipv4   = var.allowed_ssh_cidr
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}

# ---------------------------------------------------------
# admin-01 -> target-01
# OUTBOUND SSH
# ---------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "admin_allow_ssh_to_target" {
  security_group_id = aws_security_group.admin_sg.id

  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.target_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "target_allow_ssh_from_admin" {
  security_group_id            = aws_security_group.target_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.admin_sg.id

}

# ---------------------------------------------------------
# target-01 -> Internet
# OUTBOUND HTTPs
# ---------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "target_allow_http" {
  security_group_id = aws_security_group.target_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

}

# ---------------------------------------------------------
# target-01 -> Internet / Cloud services
# OUTBOUND HTTPS
# ---------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "target_allow_https" {
  security_group_id = aws_security_group.target_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# Laptop
#    │
#    │ TCP 22
#    │
#    ▼
# ┌─────────────────┐
# │    admin-sg     │
# │                 │
# │ IN: Laptop :22 │
# │ OUT: target :22│
# └────────┬────────┘
#          │
#          │ SSH 22
#          ▼
# ┌─────────────────────┐
# │      target-sg      │
# │                     │
# │ IN: admin-sg :22    │
# │                     │
# │ OUT: 0.0.0.0/0 :80  │
# │ OUT: 0.0.0.0/0 :443 │
# └──────────┬──────────┘
#            │
#            ├──────────> Internet :80/443
#            │
#            └──────────> AWS services :443