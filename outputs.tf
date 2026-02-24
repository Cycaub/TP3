# Affiche l'URL publique pour accéder à votre application
output "alb_dns_name" {
  description = "L'adresse URL du Load Balancer pour accéder au site"
  value       = aws_lb.main_alb.dns_name
}

# Affiche les IPs privées des serveurs (utile pour le debug)
output "web_server_1_private_ip" {
  value = aws_instance.web_server_1.private_ip
}

output "web_server_2_private_ip" {
  value = aws_instance.web_server_2.private_ip
}