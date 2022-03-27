output "webserver_ip_address" {
  value       = aws_instance.webserver.public_ip
  description = "The public IP address of the web server instance."
}
