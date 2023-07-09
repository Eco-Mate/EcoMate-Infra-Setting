resource "aws_instance" "ecomate_instance" {
  ami = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"
}