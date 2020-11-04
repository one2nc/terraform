resource "aws_security_group" "webserver_alb_sg" {
  name = "webserver_alb_sg"
  vpc_id = aws_vpc.sitaram_poc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "webserver_alb" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.webserver_alb_sg.id]
}

resource "aws_lb_listener" "webserver" {
  load_balancer_arn = aws_lb.webserver_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.webserver_alb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "webserver_alb_tg" {
  name     = "webserver-alb-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.sitaram_poc.id

  health_check {
    path                = "/"
    port                = var.server_port
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "webserver_a" {
  target_group_arn = aws_lb_target_group.webserver_alb_tg.arn
  target_id        = aws_instance.webserver_a.id
  port             = var.server_port
}

resource "aws_lb_target_group_attachment" "webserver_b" {
  target_group_arn = aws_lb_target_group.webserver_alb_tg.arn
  target_id        = aws_instance.webserver_b.id
  port             = var.server_port
}