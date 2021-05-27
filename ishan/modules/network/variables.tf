variable "vpc" {
  type = object({
    name = string
    cidr = string
  })
  default = {
    name = ""
    cidr = "10.0.0.0/16"
  }
}

variable "public_subnet1" {
  type = object({
    cidr = string
  })
  default = {
    cidr = "10.0.1.0/24"
  }
}

variable "private_subnet1" {
  type = object({
    cidr = string
  })
  default = {
    cidr = "10.0.2.0/24"
  }
}

variable "public_subnet2" {
  type = object({
    cidr = string
  })
  default = {
    cidr = "10.0.3.0/24"
  }
}

variable "private_subnet2" {
  type = object({
    cidr = string
  })
  default = {
    cidr = "10.0.4.0/24"
  }
}

variable "my_ip" {
  type = string
}
