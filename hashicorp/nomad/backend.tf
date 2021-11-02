terraform {
  backend "s3" {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "nomad/"
    region = "us-east-2"
  }
}
