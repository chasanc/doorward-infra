# Bucket, region and key are not committed: pass them at init time, one state per environment, e.g.
#   terraform init -backend-config="bucket=<state-bucket>" -backend-config="region=<region>" \
#     -backend-config="key=doorward-infra/dev.tfstate"
terraform {
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
