variable "AWS_REGION" {
    description = "Region of the VPC"
    default     = "ap-south-1"
}

variable "environment" {
 description = "Environment"
 default     = "Test-one2n"
}

variable "vpc_cidr" {
  description = "The IP range to use for the VPC"
  default     = "172.16.0.0/16"
}


variable "public_cidrs" {
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
  type        = list
  description = "List of public subnet CIDR blocks"
}


variable "private_cidrs" {
  default     = ["172.16.3.0/24", "172.16.4.0/24"]
  type        = list
  description = "List of private subnet CIDR blocks"
}



variable "aws_availability_zones" {
  default     = ["ap-south-1a", "ap-south-1b"]
  type        = list
  description = "List of availability zones"
}


variable "instance" {
  type    = string
  default = "t2.micro"
}

variable "bastian_count" {
    type    = number
    default = 2
}


variable key_name {
  type    = string
  default = "bastian"
}

variable s3_bucket_name {
  type = string
  description = "Bucket name used for registry service."
}

variable aws_ami {
  type    = string
  default = "ami-0851b76e8b1bce90b"
}

variable "instance_count" {
  description = "No. of service instance to provision."
  type        = number
  default = 1
}
variable "instance_count_1" {
  description = "No. of service instance to provision."
  type        = number
  default = 2
}
