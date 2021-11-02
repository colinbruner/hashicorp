data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "network/"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "hashicorp-sandbox-backend-umccr7mf"
    key    = "iam/"
    region = "us-east-2"
  }
}
