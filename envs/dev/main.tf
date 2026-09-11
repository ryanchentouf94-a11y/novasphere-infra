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

# VPC sur deux zones
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "novasphere-${var.environment}"
  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway      = false
  map_public_ip_on_launch = true
}

# Security Group de l'ALB
resource "aws_security_group" "alb" {
  name        = "novasphere-${var.environment}-alb"
  description = "Trafic HTTP vers ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group des instances
resource "aws_security_group" "web" {
  name        = "novasphere-${var.environment}-web"
  description = "HTTP uniquement depuis ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP depuis ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Modele utilise par l'Auto Scaling Group
resource "aws_launch_template" "web" {
  name_prefix = "novasphere-${var.environment}-"

  image_id               = data.aws_ami.debian.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  # replace() evite les problemes CRLF du fichier cree sous Windows
  user_data = base64encode(
    replace(file("${path.module}/bootstrap.sh"), "\r\n", "\n")
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "novasphere-${var.environment}-web"
    }
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "novasphere-${var.environment}"
  load_balancer_type = "application"

  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]
}

# Groupe de cibles
resource "aws_lb_target_group" "web" {
  name     = "novasphere-${var.environment}-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

# Listener HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name = "novasphere-${var.environment}-web"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = [aws_lb_target_group.web.arn]

  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "novasphere-${var.environment}-web"
    propagate_at_launch = true
  }
}