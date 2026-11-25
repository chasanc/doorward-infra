# doorward-infra

Trunk-based ECS/ECR CI/CD and AWS Terraform for `chasanc/doorward`.

Status: milestone 1 (CI skeleton + ECR module). Architecture, promotion flow, OIDC setup and cost table land in later milestones.

## Checks

`ci.yml` runs on every PR with no AWS account: `terraform fmt -check`, `validate`, `tflint`, `trivy config`, `actionlint`.

Locally: `make validate`.
