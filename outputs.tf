output "webserver_alb_address" {
  value       = aws_lb.cluster_alb.dns_name
  description = "The public DNS of the web server cluster load balancer."
}

#output "webserver_cluster_ip_addresses" {
#  value       = aws_autoscaling_group.webservers[*].public_ip
#  description = "The public IP addresses of the web server cluster instances."
#}

output "debug" {
  value       = data.aws_subnets.default.ids
  description = "Debug"
}
