variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "admin_cidr" {
  type = string

  validation {
    condition     = var.admin_cidr != "0.0.0.0/0" && can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr doit etre un CIDR valide et ne peut pas etre 0.0.0.0/0."
  }
}

variable "open_ports" {
  type    = list(number)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}