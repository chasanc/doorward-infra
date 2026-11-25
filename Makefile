TF := terraform -chdir=infra/terraform
ENV ?= dev

.PHONY: fmt validate plan

fmt:
	$(TF) fmt -recursive

validate:
	$(TF) fmt -check -recursive
	$(TF) init -backend=false -input=false
	$(TF) validate

# Needs real AWS credentials and the state bucket: make plan ENV=dev BUCKET=<state-bucket>
plan:
	$(TF) init -input=false -reconfigure -backend-config="bucket=$(BUCKET)" -backend-config="region=us-east-1"
	$(TF) plan -var-file=envs/$(ENV).tfvars
