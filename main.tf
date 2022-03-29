provider "aws" {

  region = "us-east-2"

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

  tag {
    key                 = "Name"
    value               = "webserver"
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
