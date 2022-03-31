output "alb_dns" {
  value       = aws_lb.cluster_alb.dns_name
  description = "The public DNS of the web server cluster load balancer."
}
