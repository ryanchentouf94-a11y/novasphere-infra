# Image Debian 12 officielle la plus recente
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IP publique du poste qui execute Terraform
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
  name    = "novasphere-${var.owner}"
}

# Cle SSH partagee par les deux serveurs
resource "aws_key_pair" "main" {
  key_name   = "${local.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Serveur Web
module "web" {
  source = "git::https://github.com/ryanchentouf94-a11y/terraform-aws-ec2-server.git?ref=v1.0.0"

  name          = "${var.owner}-web"
  ami_id        = data.aws_ami.debian.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name
  admin_cidr    = local.my_cidr
  open_ports    = [80]

  tags = {
    Role = "web"
  }
}

# Serveur de supervision
module "monitoring" {
  source = "git::https://github.com/ryanchentouf94-a11y/terraform-aws-ec2-server.git?ref=v1.0.0"

  name          = "${var.owner}-monitoring"
  ami_id        = data.aws_ami.debian.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name
  admin_cidr    = local.my_cidr
  open_ports    = []

  tags = {
    Role = "monitoring"
  }
}

# Inventaire Ansible genere automatiquement
resource "local_file" "inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/inventory.tftpl", {
    web_ip        = module.web.public_ip
    monitoring_ip = module.monitoring.public_ip
  })
}