resource "aws_instance" "ecomate_instance" {
  ami = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.ecomate_sg.id ]
  tags = {
    Name = "ecomate"
  }
}

resource "aws_security_group" "ecomate_sg" {
  # http 연결 허용
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "Allow all outbound traffic"
  }

  tags = {
    Name = "ecomate_instance_sg"
  }
}

# ssh 연결 허용
resource "aws_security_group_rule" "ecomate_sg_rule_ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecomate_sg.id
}

# https 연결 허용
resource "aws_security_group_rule" "ecomate_sg_rule_https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecomate_sg.id
}

# jenkins 연결 포트 허용
resource "aws_security_group_rule" "ecomate_sg_rule_jenkins" {
  type = "ingress"
  from_port = 9090
  to_port = 9090
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecomate_sg.id
}