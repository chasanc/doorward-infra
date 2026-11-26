TF := terraform -chdir=infra/terraform
ENV ?= dev
# dev is the QA stage, prod is the PROD stage; cluster, service and log group share one name.
NAME := doorward-$(if $(filter prod,$(ENV)),prod,qa)

.PHONY: fmt validate plan health logs

fmt:
	$(TF) fmt -recursive

validate:
	$(TF) fmt -check -recursive
	$(TF) init -backend=false -input=false
	$(TF) validate

# Needs real AWS credentials and the state bucket: make plan ENV=dev BUCKET=<state-bucket>
plan:
	$(TF) init -input=false -reconfigure -backend-config="bucket=$(BUCKET)" -backend-config="region=us-east-1" -backend-config="key=doorward-infra/$(ENV).tfstate"
	$(TF) plan -var-file=envs/$(ENV).tfvars

# Read-only. Needs AWS credentials: make health ENV=prod
health:
	aws ecs describe-services --cluster $(NAME) --services $(NAME) \
	  --query 'services[0].{running:runningCount,desired:desiredCount,deployments:deployments[].{state:rolloutState,status:status,taskDef:taskDefinition}}'

# Read-only. Tails the service log group: make logs ENV=prod
logs:
	aws logs tail /ecs/$(NAME) --since 30m --follow
