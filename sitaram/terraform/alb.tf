output "alb_dns_name" {
  value       = aws_lb.webserver_alb.dns_name
  description = "The domain name of the load balancer"
}

resource "aws_security_group" "webserver_alb_sg" {
  name                   = "${local.project_prefix}_alb_sg"
  vpc_id                 = aws_vpc.main_vpc.id
  revoke_rules_on_delete = true
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.default_route]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.default_route]
  }
}

resource "aws_lb" "webserver_alb" {
  name               = "${local.project_prefix}-web-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
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
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "webserver" {
  count            = var.service.count
  target_group_arn = aws_lb_target_group.webserver_alb_tg.arn
  target_id        = aws_instance.webserver[count.index].id
  port             = 80
}