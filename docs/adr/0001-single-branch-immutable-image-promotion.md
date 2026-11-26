# 0001. Single branch, immutable image promotion

Status: accepted

## Context

Release branches and per-environment rebuilds let PROD run bytes nobody tested, and mutable tags (`latest`, `qa`) make it unclear what is deployed.

## Decision

- One long-lived branch, `main`. Every push builds one image.
- ECR repositories are fully `IMMUTABLE`, one per environment, with no pointer tags.
- QA gets `vX.Y.Z-beta.N`. Promotion copies those exact bytes to the PROD repository as `vX.Y.Z` (pull, re-tag, push) and verifies the digests are equal.
- The release git tag is cut on the beta's commit only after PROD is healthy.
- "Latest beta" comes from git tags.

## Consequences

- What passed QA is what runs in PROD, provably (same digest).
- A failed promote leaves no release tag, so it can be retried cleanly.
- Pull and push is slower than an ECR manifest copy, but ECR does not share layers across repositories, so a manifest-only copy is not available.
- Rollback is a promote of an older beta or a redeploy of an older `vX.Y.Z`, never a rebuild.
