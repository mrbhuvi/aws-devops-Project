terraform {
  backend "s3" {
    bucket       = "terraform-state-bhuvi-2026-prod"
    key          = "terraform-aws-html-app/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}