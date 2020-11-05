
variable "region" {
    type = string
    default ="ap-south-1"
}

variable "server_port" {
    type = number
    default = 8080
}

variable "azs_list" {
    type = list(string)
    default = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
    type = string
    default = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
    type = string
    default = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
    type = string
    default = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
    type = string
    default = "10.0.4.0/24"
}

variable "public_subnet_cidr" {
    type = map(string)
    default = {
        "Public A" = "10.0.1.0/24",
        "Public B" = "10.0.2.0/24"
    }
}

variable "private_subnet_cidr" {
    type = map(string)
    default = {
        "Public A" = "10.0.3.0/24",
        "Public B" = "10.0.4.0/24"
    }
}