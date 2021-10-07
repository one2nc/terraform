resource "aws_security_group" "alb_sg" {
  name   = "${local.project_name}-alb-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress = [{
    cidr_blocks      = [local.default_route]
    description      = "HTTP"
    from_port        = 80
    protocol         = "tcp"
    to_port          = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = [local.default_route]
    description      = "HTTPS"
    from_port        = 443
    protocol         = "tcp"
    to_port          = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    }, {
    cidr_blocks      = [local.default_route]
    description      = "HTTP"
    from_port        = 3000
    protocol         = "tcp"
    to_port          = 3000
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  egress = [{
    cidr_blocks      = [local.default_route]
    description      = "Public"
    from_port        = 0
    protocol         = -1
    to_port          = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = merge({
    Name = "${local.project_name}-alb-sg"
  }, local.tags)
}

# Load Balancer and Target Group
resource "aws_lb" "alb" {
  name               = "${local.project_name}-service-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb_sg.id]

  tags = merge({
    Name = "${local.project_name}-service-alb"
  }, local.tags)
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "service-alb-tg"
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

  tags = merge({
    Name = "${local.project_name}-service-alb"
  }, local.tags)
}

resource "aws_lb_target_group_attachment" "service" {
  for_each         = aws_instance.service
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.service[each.key].id
  port             = 80
}

resource "aws_lb_listener" "service_80" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "alb_tg_hello" {
  name     = "hello-alb-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    port                = 3000
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge({
    Name = "${local.project_name}-hello-alb"
  }, local.tags)
}

resource "aws_lb_target_group_attachment" "hello" {
  for_each         = aws_instance.service
  target_group_arn = aws_lb_target_group.alb_tg_hello.arn
  target_id        = aws_instance.service[each.key].id
  port             = 3000
}

resource "aws_lb_listener" "hello_3000" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_tg_hello.arn
    type             = "forward"
  }
}
