HOOKS=.git/hooks

setup-git:
	@echo Setting up git hooks
	@mkdir -p $(HOOKS)
	@(cd $(HOOKS) && ln -sf ../../.github/hooks/* .)
	@(cd ../../)
.PHONY: setup-git

pre-push:
	@echo Running pre push checks
	@echo Checking file formating
	@$(prettier)
	@echo Checking yaml configurations
	@./scripts/fluxcd-validate-bew.sh
	@echo All prep push tasks executed
#	@./scripts/verify-fluxcd.sh
.PHONY: pre-push

prettier:
	@prettier --config .github/.prettierrc -c ./kubernetes
.PHONY: prettier
