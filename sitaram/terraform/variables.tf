
variable "region" {
    type = string
}

variable "server_port" {
    type = number
}

variable "default_route" {
    type = string
    default = "0.0.0.0/0"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}