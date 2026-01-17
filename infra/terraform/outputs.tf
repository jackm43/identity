output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.identity.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.identity.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.identity.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i \"Github and SSH Key.pem\" ubuntu@${aws_instance.identity.public_ip}"
}
