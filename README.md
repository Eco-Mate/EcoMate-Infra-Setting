# Ecomate-Infra-Setting

아래 예시 파일처럼 variable을 설정하거나 환경변수를 추가한 후 사용 가능합니다.

```terraform
variable "db_password" {
  type = 
  default = "[database password]"
}

variable "aws_secret_key" {
    type = string
    default = "[aws secret key]"
}

variable "aws_access_key" {
    type = string
    default = "[aws access key]"
}
```
