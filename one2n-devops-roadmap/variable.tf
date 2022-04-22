variable "AWS_REGION" {
  description = "Region of the VPC"
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment"
  default     = "terraform-one2n"
}

variable "vpc_cidr" {
  description = "The IP range to use for the VPC"
  default     = "172.16.0.0/16"
}


variable "public_cidrs" {
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
  type        = list(any)
  description = "List of public subnet CIDR blocks"
}


variable "private_cidrs" {
  default     = ["172.16.3.0/24", "172.16.4.0/24"]
  type        = list(any)
  description = "List of private subnet CIDR blocks"
}

variable "availablity_zones" {
  description = "Availablity zones"
  type        = list(string)
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "bastian_count" {
  type    = number
  default = 2
}

variable "key_name" {
  type    = string
  default = "bastian"
}

variable "s3_bucket_name" {
  type        = string
  description = "Bucket name used for registry service."
  default     = "one2n-tf"
}

variable "aws_ami" {
  type    = string
  default = "ami-0851b76e8b1bce90b"
}

variable "instance_count" {
  description = "No. of service instance to provision."
  type        = number
  default     = 1
}


variable "instance_count_1" {
  description = "No. of service instance to provision."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "mysql DB name"
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Username of databse"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password of databse"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port of mysql databse"
  type        = number
  default     = 3306
}

variable "db_engine" {
  description = "Database engine mysql"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance" {
  description = "Database instance class"
  type        = string
  default     = "db.t2.micro"

}
