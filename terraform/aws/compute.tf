resource "aws_key_pair" "netdebug" {
  key_name   = "netdebug-key"
  public_key = file(var.ssh_public_key_path)
}

module "ec2_instances" {
  source = "./modules/ec2-instance"

  for_each = local.instances

  name                        = "${var.project_name}-${each.key}"
  ami_id                      = data.aws_ami.amazon_linux.id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  security_group_ids          = each.value.security_group_ids
  key_name                    = aws_key_pair.netdebug.key_name
  associate_public_ip_address = each.value.associate_public_ip_address

  tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
    Role          = "admin"
  }
}

moved {
  from = aws_instance.admin_01
  to   = module.ec2_instances["admin-01"].aws_instance.this
}

moved {
  from = aws_instance.target_01
  to   = module.ec2_instances["target-01"].aws_instance.this
}