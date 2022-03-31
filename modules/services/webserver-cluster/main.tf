data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    # Replace this with your bucket name!
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = var.db_remote_state_region
  }
}

data "aws_vpc" "default" {
  default = "true"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]

  }
}

data "aws_ami" "latest-ubuntu-beaver" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "webserver" {
  image_id        = data.aws_ami.latest-ubuntu-beaver.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.webserver.id]

  user_data = templatefile("${path.module}/user_data.sh.tftpl", { db_address = data.terraform_remote_state.db.outputs.address, db_port = data.terraform_remote_state.db.outputs.port, webserver_port = var.webserver_port })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webservers" {
  name                 = var.cluster_name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  max_size             = var.max_size
  min_size             = var.min_size
  launch_configuration = aws_launch_configuration.webserver.name

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_security_group" "webserver" {
  name = "${var.cluster_name}-sg"
}

resource "aws_security_group_rule" "allow_instance_http_incoming" {
  type              = "ingress"
  security_group_id = aws_security_group.webserver.id

  from_port   = var.webserver_port
  to_port     = var.webserver_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb-sg"
}

resource "aws_security_group_rule" "allow_lb_http_incoming" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = "tcp"
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_lb_all_outgoing" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.all_protocols
  cidr_blocks = local.all_ips
}

resource "aws_lb" "cluster_alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cluster_alb.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found :("
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name        = "${var.cluster_name}-lb-tg"
  target_type = "instance"
  port        = var.webserver_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg-http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

locals {
  http_port     = 80
  any_port      = 0
  all_ips       = ["0.0.0.0/0"]
  all_protocols = "-1"
}
