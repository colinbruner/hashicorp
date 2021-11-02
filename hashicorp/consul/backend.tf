terraform {
  backend "s3" {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "consul/"
    region = "us-east-2"
  }
}
