output "alb_dns_name" {
  description = "Nom DNS de l'Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "vpc_id" {
  description = "ID du VPC NovaSphere"
  value       = module.vpc.vpc_id
}