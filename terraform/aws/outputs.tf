output "instance_ids" {
  description = "EC2 instance IDs by instance name"

  value = {
    for name, instance in module.ec2_instances :
    name => instance.instance_id
  }
}

output "private_ips" {
  description = "Private IP addresses by instance name"

  value = {
    for name, instance in module.ec2_instances :
    name => instance.private_ip
  }
}

output "public_ips" {
  description = "Public IP addresses by instance name"

  value = {
    for name, instance in module.ec2_instances :
    name => instance.public_ip
  }
}