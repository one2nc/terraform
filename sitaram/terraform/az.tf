variable "max_az" {
  default = 1
}

data "aws_availability_zones" "az_list" {
  state = "available"
}

resource "null_resource" "az_names" {
  triggers = {
    names = join(",", slice(data.aws_availability_zones.az_list.names, 0, min(var.max_az, length(data.aws_availability_zones.az_list.names))))
  }
}

resource "null_resource" "az_count" {
  triggers = {
    total = length(split(",", null_resource.az_names.triggers.names))
  }
}