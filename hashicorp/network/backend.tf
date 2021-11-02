terraform {
  backend "s3" {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "network/"
    region = "us-east-2"
  }
}
