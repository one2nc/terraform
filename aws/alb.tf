variable "health_check_path" {
  default = "/"
}

resource "aws_security_group" "alb_sg" {
  vpc_id                 = aws_vpc.vpc.id
  name                   = "${var.meta.env}-alb-sg"
  revoke_rules_on_delete = true
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
}

resource "aws_alb" "alb" {
  internal           = false
  load_balancer_type = "application"
  name               = "${var.meta.env}-alb"
  subnets            = aws_subnet.private.*.id
  security_groups    = [aws_security_group.alb_sg.id]

}

resource "aws_alb_target_group" "alb-80" {
  name        = "${var.meta.env}-alb-target-group-80"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
  }
}

resource "aws_alb_listener" "alb-80" {

  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.alb-80.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "alb-80" {
  count            = 2
  target_group_arn = aws_alb_target_group.alb-80.arn
  target_id        = element(aws_instance.worker.*.id, count.index)
  port             = 80
}

