output "admin_public_ip" {
  description = "Public IP address of admin-01"
  value       = aws_instance.admin_01.public_ip
}

output "admin_private_ip" {
  description = "Private IP address of admin-01"
  value       = aws_instance.admin_01.private_ip
}

output "target_private_ip" {
  description = "Private IP address of target-01"
  value       = aws_instance.target_01.private_ip
}