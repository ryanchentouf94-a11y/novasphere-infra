terraform {
  backend "s3" {
    bucket       = "novasphere-tfstate-rch-588859219682"
    key          = "novasphere/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}