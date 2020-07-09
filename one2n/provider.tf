variable "profile" {
  type = string
}

variable "region" {
  type = string
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

terraform {
  backend "s3" {
    bucket  = ""
    profile = "personal"
    key     = "one2n/terraform.tfstate"
    region  = "ap-south-1"
  }
}
