# Release process

One branch (`main`), one image per commit, promoted by tag. Nothing is rebuilt for PROD.

```
push to main ──► build once ──► QA ECR  vX.Y.Z-beta.N ──► QA ECS (auto)
                                   │
        workflow_dispatch + reviewer approval (production Environment)
                                   ▼
                      copy same bytes ──► PROD ECR  vX.Y.Z ──► PROD ECS
                                   │
                         healthy ──► git tag vX.Y.Z on the beta's commit
```

## Tags

All tags are immutable (ECR `IMMUTABLE`, git tags never moved). There are no `latest` or `qa` pointer tags.

| Tag | Where | Created by | Meaning |
|---|---|---|---|
| `vX.Y.Z-beta.N` | QA ECR and git | `ecs-deploy.yml` on every push to `main` | A build that is or was in QA. `X.Y.Z` is the next patch after the latest release, `N` counts up |
| `vX.Y.Z` | PROD ECR and git | `ecs-promote.yml` | The exact beta image running in PROD. The git tag is cut only after PROD is healthy |

"Latest beta" is resolved from git tags (`vX.Y.Z-beta.N`, highest version), never from an image pointer.

## Cutting a release

1. Merge to `main`. QA deploys itself; check the run is green and the rollout `COMPLETED`.
2. Run the promote workflow (`workflow_dispatch`), leaving `beta-tag` empty for the latest beta or naming one.
3. A required reviewer approves the `production` Environment.
4. The workflow refuses if `vX.Y.Z` already exists, copies the image, checks the digests match, deploys, and cuts the tag.

A re-run after a failed deploy reuses the PROD image when its digest matches. A different digest under the same tag is a hard failure.

## Rolling back

See [the rollback runbook](runbooks/failed-promote-rollback.md).
