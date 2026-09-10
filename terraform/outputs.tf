output "web_public_ip" {
  value = module.web.public_ip
}

output "web_instance_id" {
  value = module.web.instance_id
}

output "monitoring_public_ip" {
  value = module.monitoring.public_ip
}

output "monitoring_instance_id" {
  value = module.monitoring.instance_id
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/novasphere admin@${module.web.public_ip}"
}