# Application Load Balancer
resource "aws_lb" "one2n_alb" {
  name               = "${var.environment}_alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.vpc_sg.id]
  subnets            = aws_subnet.public_subnet.*.id

  tags = {
    Name = "${var.environment}_alb"
  }
}

# Target group
resource "aws_alb_target_group" "one2n_tg" {
  name     = "${var.environment}_tg"
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

  tags = {
    Name = "${var.environment}_target_group"
  }
}


resource "aws_lb_target_group_attachment" "alb_tg_attach" {
  count            = length(aws_instance.service_instance_1)
  target_group_arn = aws_alb_target_group.one2n_tg.arn
  target_id        = aws_instance.service_instance_1[count.index].id
  port             = 80

  tags = {
    Name = "${var.environment}_tg_attach"
  }
}

resource "aws_lb_target_group_attachment" "alb_tg_attach1" {
  count            = length(aws_instance.service_instance)
  target_group_arn = aws_alb_target_group.one2n_tg.arn
  target_id        = aws_instance.service_instance[count.index].id
  port             = 80

  tags = {
    Name = "${var.environment}_tg_attach"
  }
}

# Listener (redirects traffic from the load balancer to the target group)
resource "aws_alb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.one2n_alb.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.one2n_tg]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.one2n_tg.arn
  }

  tags = {
    Name = "${var.environment}_alb_listener"
  }
}
