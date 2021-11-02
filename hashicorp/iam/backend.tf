terraform {
  backend "s3" {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "iam/"
    region = "us-east-2"
  }
}
