provider "aws" {

  region = "us-east-2"

}

resource "aws_instance" "webserver" {
  ami             = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.webserver.name]

  user_data = <<-EOF
              #!/bin/bash
              echo "Webserver is up and running" >> index.html
              nohup busybox httpd -f -p ${var.webserver_port} &
              EOF

  tags = {
    Name = "terraform-webserver"
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
