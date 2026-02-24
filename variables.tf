variable "vpc_cidr" {
    description = "Main VPC"
    type = string
  default = "10.0.0.0/16"
}
variable "client" {
  type        = string
  description = "Le nom du client passé par Jenkins"
}

variable "env" {
  type        = string
  description = "L'environnement (dev, staging, prod) passé par Jenkins"
}
