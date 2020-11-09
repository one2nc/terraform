data "aws_availability_zones" "az_list" {
    state = "available"
}

resource "null_resource" "az_names" {
    triggers = {
        names = data.aws_availability_zones.available.names
    }
}

resource "null_resource" "az_count" {
    triggers = {
        total = length(null_resource.az_names.triggers.names)
    }
}