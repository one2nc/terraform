resource "aws_lb" "main" {
  name               = "terraform-hello-main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_default_sec_grp_id]
  subnets            = [var.public_subnet1_id, var.public_subnet2_id]

  enable_deletion_protection = true

  tags = {
    Name = "terraform-hello-main-alb"
  }
}
