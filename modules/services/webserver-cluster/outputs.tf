output "alb_dns" {
  value       = aws_lb.cluster_alb.dns_name
  description = "The public DNS of the web server cluster load balancer."
}

output "asg_name" {
  value       = aws_autoscaling_group.webservers.name
  description = "The name of the Auto Scaling Group"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}
