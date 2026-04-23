.PHONY: help setup install notebook dev smoke build up down logs restart clean clean-all

.DEFAULT_GOAL := help

BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

VENV := .venv
UV := uv
JUPYTER_PORT ?= 8888

help: ## Show this help
	@echo "$(BLUE)Data Engineering Medallion - learnwithparam.com$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Initial setup (create .env, install uv, uv sync)
	@if [ ! -f .env ]; then \
		echo "$(BLUE)Creating .env file...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)OK: .env created$(NC)"; \
	else \
		echo "$(YELLOW).env already exists$(NC)"; \
	fi
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "$(BLUE)Installing uv...$(NC)"; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	else \
		echo "$(GREEN)OK: uv is installed$(NC)"; \
	fi
	@echo "$(BLUE)Syncing dependencies...$(NC)"
	@$(UV) sync
	@echo "$(GREEN)OK: Environment ready$(NC)"

install: ## Install dependencies via uv sync
	@$(UV) sync

notebook: ## Start JupyterLab on $(JUPYTER_PORT)
	@echo "$(BLUE)Starting JupyterLab on http://localhost:$(JUPYTER_PORT)$(NC)"
	@$(UV) run jupyter lab --no-browser --port $(JUPYTER_PORT) --ip 0.0.0.0

dev: setup notebook ## Setup and launch JupyterLab

smoke: ## Run the notebook end-to-end headless
	@bash smoke_test.sh

build: ## Build Docker image
	docker compose build

up: ## Start JupyterLab container
	docker compose up -d

down: ## Stop container
	docker compose down

logs: ## View container logs
	docker compose logs -f

restart: down up ## Restart container

clean: ## Remove venv, cache, notebook checkpoints
	rm -rf $(VENV)
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -f /tmp/medallion_smoke_out.ipynb
	@$(UV) cache clean

clean-all: clean down ## Clean everything including Docker volumes
	docker compose down -v
