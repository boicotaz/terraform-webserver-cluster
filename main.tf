provider "aws" {

  region = "us-east-2"

}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-state-425832464758"
    key    = "stage/services/webcluster/terraform.tfstate"
    region = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
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
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.webserver.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Webserver is up and running" >> index.html
              nohup busybox httpd -f -p ${var.webserver_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webservers" {
  name                 = "webserver-cluster"
  vpc_zone_identifier  = data.aws_subnets.default.ids
  max_size             = 3
  min_size             = 2
  launch_configuration = aws_launch_configuration.webserver.name

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "webserver-cluster"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "webserver" {
  name = "terraform-webserver-sg"

  ingress {
    from_port   = var.webserver_port
    to_port     = var.webserver_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name = "webserver-alb-sg"

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

resource "aws_lb" "cluster_alb" {
  name               = "webserver-cluster-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cluster_alb.arn
  port              = "80"
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
  name        = "webserver-cluster-lb-tg"
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
