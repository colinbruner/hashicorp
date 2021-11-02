terraform {
  backend "s3" {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "global/"
    region = "us-east-2"
  }
}
