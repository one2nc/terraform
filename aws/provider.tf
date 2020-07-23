variable "profile" {
  type = string
}

variable "region" {
  type = string
}

provider "aws" {
  profile = var.profile
  region  = var.region
}
