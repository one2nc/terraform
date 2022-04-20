# Application Load Balancer
resource "aws_lb" "my-alb" {
  name               = "${var.environment}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.test_sg.id]
  subnets            = "${aws_subnet.public_subnet.*.id}"
}

# Target group
resource "aws_alb_target_group" "my-target-group" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id


  health_check {
    path                = "/"
    port                = "80"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}


resource "aws_lb_target_group_attachment" "my_alb_tg" {
  count            = length(aws_instance.service_instance-1)
  target_group_arn = aws_alb_target_group.my-target-group.arn
  target_id        = aws_instance.service_instance-1[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "my_alb_tg1" {
  count            = length(aws_instance.service_instance)
  target_group_arn = aws_alb_target_group.my-target-group.arn
  target_id        = aws_instance.service_instance[count.index].id
  port             = 80
}

# Listener (redirects traffic from the load balancer to the target group)
resource "aws_alb_listener" "alb-http-listener" {
  load_balancer_arn = aws_lb.my-alb.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.my-target-group]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.my-target-group.arn
  }
}
