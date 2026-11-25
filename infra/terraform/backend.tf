# Bucket and region are not committed: pass them at init time, e.g.
#   terraform init -backend-config="bucket=<state-bucket>" -backend-config="region=<region>"
terraform {
  backend "s3" {
    key          = "doorward-infra/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
