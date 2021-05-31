variable "vpc_id" {
  type = string
}

variable "public_subnet1_id" {
  type = string
}

variable "public_subnet2_id" {
  type = string
}

variable "alb_default_sec_grp_id" {
  type = string
}

variable "alb_target_deregistration_delay" {
  type = number
  default = 1800
}

variable "app_public_instance1_id" {
  type = string
}

variable "app_public_instance2_id" {
  type = string
}
