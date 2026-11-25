# doorward-infra

Trunk-based ECS/ECR CI/CD and AWS Terraform for `chasanc/doorward`.

Status: milestone 2 (network, ECS Fargate service, IAM with GitHub OIDC). The deploy and promote workflows, architecture diagram and cost table land in later milestones.

## Layout

One Terraform root (`infra/terraform`) per environment, selected by tfvars and a separate state key:

| Environment | Stage | Creates |
|---|---|---|
| `dev` | QA | VPC, `doorward-qa` ECR repo, ECS cluster and service, IAM roles, GitHub OIDC provider |
| `prod` | PROD | VPC, `doorward-prod` ECR repo, ECS cluster and service, IAM roles |

Modules: `network`, `ecr`, `ecs-service`, `iam`.

## OIDC deploy roles

No static AWS keys. Each environment has a `<app>-<stage>-deploy` role that GitHub Actions assumes with `sts:AssumeRoleWithWebIdentity`. The trust policy pins the audience and the subject:

| Role | Allowed subject (`sub`) |
|---|---|
| QA | `repo:<github_repo>:ref:refs/heads/main` |
| PROD | `repo:<github_repo>:environment:production` (jobs behind the required-reviewer gate) |

`github_repo` defaults to `chasanc/doorward`, the application repo whose workflows call the reusable ones here. The PROD role may also read the QA repository so it can re-tag the exact tested image.

Apply `dev` first: it creates the OIDC provider, which is one per AWS account.

## Checks

`ci.yml` runs on every PR with no AWS account: `terraform fmt -check`, `validate`, `tflint`, `trivy config`, `actionlint`.

Locally: `make validate`.
