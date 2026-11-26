# Runbook: failed promote or bad release

## Alert standard

| Level | When | Response |
|---|---|---|
| Page | PROD service unhealthy or the rollout is failing right now | Act immediately, follow the steps below |
| Ticket | A promote failed before touching PROD, or QA is red | Fix in working hours; PROD is unaffected |

## 1. Look

```
make health ENV=prod
```

Shows the service's deployments and `rolloutState`. `COMPLETED` is good. `FAILED` or `IN_PROGRESS` that never ends means a bad deploy.

`services-stable` also passes after the circuit breaker rolls back, so the promote workflow checks `rolloutState`. A green wait step alone proves nothing.

## 2. Decide

- **Promote failed before the deploy step** (copy or digest check): PROD is untouched. Fix the cause and re-run the promote. Re-runs reuse the PROD image if the digest matches.
- **Deploy failed, circuit breaker rolled back**: PROD is already on the previous task definition. Check `make health ENV=prod`, then investigate with `make logs ENV=prod`. No release tag was cut, so re-run the promote after fixing.
- **Release went out and is bad**: roll back (below).

## 3. Roll back

PROD keeps every released `vX.Y.Z` image (immutable). Redeploy the previous one by registering a task definition with it and updating the service:

```
aws ecs describe-services --cluster doorward-prod --services doorward-prod \
  --query 'services[0].taskDefinition'
aws ecs list-task-definitions --family-prefix doorward-prod --sort DESC --max-items 5
aws ecs update-service --cluster doorward-prod --service doorward-prod \
  --task-definition <previous task definition ARN>
aws ecs wait services-stable --cluster doorward-prod --services doorward-prod
make health ENV=prod
```

The newest revision's image tag is the bad release; pick the revision whose image is the last good `vX.Y.Z`. Do not move or delete git or ECR tags. After the incident, fix forward on `main` and promote a new beta.

## 4. Follow up

Open a ticket for the root cause. Note the bad `vX.Y.Z` so nobody promotes a beta that contains it.
