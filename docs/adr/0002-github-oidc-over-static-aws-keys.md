# 0002. GitHub OIDC over static AWS keys

Status: accepted

## Context

CI needs to push images and update ECS. Long-lived access keys in repository secrets leak, never expire and cannot be scoped to a branch or an approval.

## Decision

Workflows assume an IAM role with `sts:AssumeRoleWithWebIdentity` through the GitHub OIDC provider. The trust policy pins the audience and the subject:

- QA role: `repo:<github_repo>:ref:refs/heads/main`
- PROD role: `repo:<github_repo>:environment:production`, so only jobs behind the required-reviewer gate can reach PROD.

The roles are least privilege: ECR push to one repository, `ecs:UpdateService` on one service, `iam:PassRole` for the two task roles only.

## Consequences

- No AWS secrets in GitHub; credentials last for the job.
- The OIDC provider is one per account, so dev creates it and prod looks it up. Apply dev first.
- Three actions need `Resource: *` because AWS offers no narrower form: `ecr:GetAuthorizationToken`, `ecs:RegisterTaskDefinition` and `ecs:DescribeTaskDefinition`.
