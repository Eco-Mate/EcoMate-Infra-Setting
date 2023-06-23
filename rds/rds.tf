# rds.tf
resource "aws_db_instance" "ecomateDB" {
  allocated_storage = 20
  availability_zone = "ap-northeast-2a"
  engine = "mysql"
  engine_version = "8.0.32"
  instance_class = "db.t2.micro"
  skip_final_snapshot = true
  identifier = "ecomate"
  username = "admin"
  password = var.db_password
  publicly_accessible = true
  port = "3306"
  tags = {
    Name = "ecomate"
  }
}

provider "aws" {
  region = "ap-northeast-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}