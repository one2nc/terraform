resource "aws_lb_target_group" "target_group_app1" {
  name                 = "terraform-hello-app1"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = var.alb_target_deregistration_delay
}

resource "aws_lb_target_group_attachment" "targets_app1_target1" {
  target_group_arn = aws_lb_target_group.target_group_app1.arn
  target_id        = var.app_public_instance1_id
  port             = 80
}

resource "aws_lb_target_group_attachment" "targets_app1_target2" {
  target_group_arn = aws_lb_target_group.target_group_app1.arn
  target_id        = var.app_public_instance2_id
  port             = 80
}
