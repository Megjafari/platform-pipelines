.DEFAULT_GOAL := help

ACTIONLINT_IMAGE := rhysd/actionlint:1.7.7
YAMLLINT_IMAGE   := cytopia/yamllint:1.35

.PHONY: help lint lint-actions lint-yaml

help: ## Show available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

lint: lint-actions lint-yaml ## Run all linters

lint-actions: ## Lint GitHub Actions workflows
	docker run --rm -v "$(CURDIR)":/repo -w /repo $(ACTIONLINT_IMAGE) -color

lint-yaml: ## Lint YAML files
	docker run --rm -v "$(CURDIR)":/data $(YAMLLINT_IMAGE) .
