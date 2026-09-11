variable "aws_region" {
  description = "Region AWS de deploiement"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Trigramme de l'etudiant"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3}$", var.owner))
    error_message = "Le trigramme doit etre compose de 3 lettres minuscules."
  }
}

variable "environment" {
  description = "Environnement de deploiement"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}