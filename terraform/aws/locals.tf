locals {
  instances = {
    admin-01 = {
      instance_type               = var.admin_instance_type
      subnet_id                   = aws_subnet.public.id
      security_group_ids          = [aws_security_group.admin_sg.id]
      associate_public_ip_address = true
    }

    target-01 = {
      instance_type               = var.target_instance_type
      subnet_id                   = aws_subnet.private.id
      security_group_ids          = [aws_security_group.target_sg.id]
      associate_public_ip_address = false
    }
  }
}