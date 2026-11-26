---
name: cut-release
description: Promote the latest QA beta image to PROD and cut the vX.Y.Z release for doorward. Use when asked to release, promote or ship to production.
---

# Cut a release

## Hard rules

- Promote only an image that passed QA. Never rebuild, never retag by hand.
- Never move or delete a git or ECR tag.
- The `production` Environment approval is a human decision. Do not approve it.

## Workflow

1. Check QA: the latest `deploy-qa` run on `main` is green and `make health ENV=dev` shows `COMPLETED`.
2. Find the beta: `git tag --list 'v*-beta.*' --sort=-v:refname | head -1`. Confirm its `vX.Y.Z` is not already a tag.
3. Run the promote workflow in the app repo with that `beta-tag` (or empty for the latest).
4. Tell the reviewer to approve the `production` Environment.
5. Watch the run until the deploy step reports `COMPLETED`.
6. Confirm `make health ENV=prod` and that the `vX.Y.Z` git tag now points at the beta's commit.

## Done when

- [ ] PROD rollout is `COMPLETED`
- [ ] `vX.Y.Z` exists in PROD ECR and as a git tag on the beta's commit
- [ ] PROD digest equals the QA digest
- [ ] On failure, `docs/runbooks/failed-promote-rollback.md` was followed
