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

## Deploying to QA

`.github/workflows/ecs-deploy.yml` is a reusable workflow (`workflow_call`). The application repo calls it on every push to `main` using `examples/deploy-qa.yml`. It:

1. computes the next `vX.Y.Z-beta.N` from git tags (next patch after the latest release),
2. builds the image once (`--provenance=false`, 3 attempts) and pushes that immutable tag to the QA ECR repo,
3. pushes the git tag on that commit,
4. registers a task definition with the new image, updates the ECS service and waits for it to be stable; it fails if the circuit breaker rolled the deploy back.

Deploys for one service queue and are never cancelled. Set repository variables `AWS_REGION` and `QA_DEPLOY_ROLE_ARN` (the `deploy_role_arn` Terraform output) in the app repo.

## Promoting to PROD

`.github/workflows/ecs-promote.yml` is a reusable workflow; the app repo triggers it by hand with `examples/promote-prod.yml` (`workflow_dispatch`, optional `beta-tag`). It runs in the `production` GitHub Environment, so required reviewers must approve before the PROD role can be assumed. It:

1. resolves the beta (the input, or the latest `vX.Y.Z-beta.N` git tag) and refuses if `vX.Y.Z` is already released,
2. copies that exact QA image into the PROD ECR repo as `vX.Y.Z` (pull, re-tag, push, no rebuild) and checks the PROD digest equals the QA digest; a re-run after a failed deploy reuses the image if the digest matches,
3. registers a task definition, updates the PROD service and fails unless the rollout is `COMPLETED`,
4. pushes the `vX.Y.Z` git tag on the beta's commit.

Create the `production` Environment with required reviewers in the app repo, and set `PROD_DEPLOY_ROLE_ARN`.

## Checks

`ci.yml` runs on every PR with no AWS account: `terraform fmt -check`, `validate`, `tflint`, `trivy config`, `actionlint`.

Locally: `make validate`.
