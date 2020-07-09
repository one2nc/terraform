variable "max_az" {
  default = 1
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "null_resource" "zones" {
  triggers = {
    names = join(",", slice(data.aws_availability_zones.available.names, 0, min(var.max_az, length(data.aws_availability_zones.available.names))))
  }
}

resource "null_resource" "zone_count" {
  triggers = {
    total = length(split(",", lookup(null_resource.zones.triggers, "names")))
  }
}
