# doorward-infra

Reusable GitHub workflows plus AWS Terraform for the `chasanc/doorward` app. See `README.md` and `docs/`.

## Hard rules

- No AWS account IDs, bucket names, employer names, ticket IDs or internal hostnames in any committed file.
- ECR stays `IMMUTABLE`. Never add a mutable pointer tag (`latest`, `qa`).
- Never rebuild for PROD. Promote copies the QA image and checks the digest.
- No static AWS keys. Auth is GitHub OIDC only.
- Pin every action by commit SHA.
- Nothing is applied to a real account from here. CI needs no AWS credentials.
- Keep the `enabled_cloudwatch_logs_exports` literal in the rds module in step with `local.log_exports`.
- Use workflow examples in `examples/`; callers do not live in this repo.

## Workflow

1. Change code, then run `make validate`.
2. CI must stay green: `terraform fmt -check`, `validate`, `tflint`, `trivy config`, `actionlint`.
3. This repo has no PRs: commit to `main` and push.
4. Releases go through `skills/cut-release/SKILL.md`.

## Done when

- [ ] `make validate` passes
- [ ] CI is green on `main`
- [ ] README and `docs/` match the change
- [ ] No identifiers from the hard rules appear in the diff
