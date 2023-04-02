terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.2"
    }
  }
}

variable "server_port" {
  description = "The port the serve will use for HTTP requests"
  default = 8080
}

# aws_availability_zones 의 데이터 소스로 aws 계정에 있는 모든 가용 AZ를 가져오도록 설정
data "aws_availability_zones" "all" {}

provider "aws" {
  region = "us-east-1"  # 북부 버지니아
}

resource "aws_instance" "example" {
  ami = "ami-40d28157"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags = {
    Name = "terraform-example"
  }
}

# 8080 포트에 대한 트래픽 허용
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP 주소 대역 포함
  }

  lifecycle {
    create_before_destroy = true
  }
}

# E2C 인스턴스를 ASG(auto scaling group)에 설정하는 시작 구성을 생성
resource "aws_launch_configuration" "example" {
  image_id      = "ami-40d28157"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# ASG 생성
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  # 인스턴스가 시작될 때 ELB 에 각 인스턴스를 등록하도록 ASG 에 요창
  load_balancers = [aws_elb.example.name]
  # 기본 설정인 EC2 : 인스턴스가 완전히 다운되었다고 판단될 경우에만 인스턴스를 비정상 상태라고 간주
  # ELB : ASG 가 대상그룹의 상태를 확인하고 비정상( + 메모리 부족 및 중요 프로세스 중단) 이라고 판별될 경우 인스턴스를 자동으로 교체하도록 지시
  health_check_type = "ELB"

  max_size = 10  # 2~10 개의 EC2 인스턴스를 생성
  min_size = 2

  tag {
    key                 = "Name"  # 인스턴스의 태그 이름 정의
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# 보안 그룹에 포트 80 번 트래픽에 대해 정의 -> resource "aws_elb" "example" 의 security_groups 에서 연동
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ELB 가 80번 포트로 HTTP 응답을 받아서 ASG 에 있는 웹 서버로 트래픽을 전달하는 설정
resource "aws_elb" "example" {
  name = "terraform-asg-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups = [aws_security_group.elb.id]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }

  # 30초마다 "/"로 HTTP 요청 -> 인스턴스의 응답이 200 OK 인지 확인
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

# ELB 의 도메인 이름을 출력 (확인 용도)
output "elb_dns_name" {
  value = aws_elb.example.dns_name
}