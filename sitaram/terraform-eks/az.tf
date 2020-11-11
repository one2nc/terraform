variable "region" {
    type = string
}

variable "az_count" {
    type = number
    default = 2
    validation {
        condition     = var.az_count > 1
        error_message = "Min 2 AZs needed for EKS."
    }
}

locals {
    min_azs = 2
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "null_resource" "az_names" {
    triggers = {
        list = join(",", slice(data.aws_availability_zones.available_zones.names, 0, min(var.az_count, length(data.aws_availability_zones.available_zones.names))))
    }
}

resource "null_resource" "azs" {
    triggers = {
        count = length(split(",", null_resource.az_names.triggers.list))
    }
}

resource "null_resource" "min_required_azs" {
    count = null_resource.azs.triggers.count < local.min_azs ? 1 : 0
    provisioner "local-exec" {
        command = <<COMMAND
            echo "Not enough AZs available" >&2
            exit 1
        COMMAND
    }
}

