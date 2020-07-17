resource "aws_security_group" "cloudfront_r_sg" {
  name        = "cloudfront_r"
  description = "Allow Inbound traffic from CloudFront Region"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "cloudfront_r"
    AutoUpdate  = "true"
    Protocol    = "https"
    Environment = var.environment
  }
}

resource "aws_security_group" "cloudfront_g_h_sg" {
  name        = "cloudfront_g_h"
  description = "Allow Inbound traffic from CloudFront Global"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "cloudfront_g_h"
    AutoUpdate  = "true"
    Protocol    = "https"
    Environment = var.environment
  }
}

resource "aws_security_group" "cloudfront_g_l_sg" {
  name        = "cloudfront_g_l"
  description = "Allow Inbound traffic from CloudFront Global"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "cloudfront_g_l"
    AutoUpdate  = "true"
    Protocol    = "https"
    Environment = var.environment
  }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudfront_r_sg.id,aws_security_group.cloudfront_g_l_sg.id,aws_security_group.cloudfront_g_h_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app_target_group" {
  name        = "app-target-group"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.alb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}
