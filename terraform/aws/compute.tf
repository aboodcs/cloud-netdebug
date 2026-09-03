resource "aws_key_pair" "netdebug" {
  key_name   = "netdebug-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_instance" "admin_01" {
  key_name                    = aws_key_pair.netdebug.key_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.admin_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.admin_sg.id]
  associate_public_ip_address = true
  tags = {
    Name          = "${var.project_name}-admin-01"
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
    Role          = "admin"
  }
}

resource "aws_instance" "target_01" {
  key_name                    = aws_key_pair.netdebug.key_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.target_sg.id]
  associate_public_ip_address = false

  tags = {
    Name          = "${var.project_name}-target-01"
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
    Role          = "admin"
  }
}