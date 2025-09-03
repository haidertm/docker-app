# Makefile for Docker development with mkcert SSL
# Usage: make [target]

# Variables
DOCKER_COMPOSE = docker-compose
CERT_DIR = ./certs
CERT_FILE = $(CERT_DIR)/app.pk.pem
CERT_KEY = $(CERT_DIR)/app.pk-key.pem
DOMAINS = app.pk www.app.pk localhost 127.0.0.1 ::1

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help command
.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)Docker Development Environment with mkcert SSL$(NC)"
	@echo "$(YELLOW)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick start:$(NC) make install && make start"

# Check if mkcert is installed
.PHONY: check-mkcert
check-mkcert:
	@command -v mkcert >/dev/null 2>&1 || { \
		echo "$(RED)mkcert is not installed!$(NC)"; \
		echo "$(YELLOW)Installing mkcert...$(NC)"; \
		sudo apt update && sudo apt install -y libnss3-tools wget; \
		wget -O /tmp/mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64; \
		chmod +x /tmp/mkcert; \
		sudo mv /tmp/mkcert /usr/local/bin/; \
		mkcert -install; \
		echo "$(GREEN)mkcert installed successfully!$(NC)"; \
	}

# Install mkcert and initial setup
.PHONY: install
install: check-mkcert ## Install mkcert and setup initial certificates
	@echo "$(YELLOW)Setting up mkcert CA...$(NC)"
	@mkcert -install
	@echo "$(GREEN)mkcert CA installed!$(NC)"
	@$(MAKE) certs
	@$(MAKE) hosts

# Check /etc/hosts
.PHONY: hosts
hosts: ## Add app.pk to /etc/hosts
	@if ! grep -q "app.pk" /etc/hosts; then \
		echo "$(YELLOW)Adding app.pk to /etc/hosts...$(NC)"; \
		echo "127.0.0.1 app.pk www.app.pk" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(GREEN)Hosts file updated!$(NC)"; \
	else \
		echo "$(GREEN)app.pk already in /etc/hosts$(NC)"; \
	fi

# Generate certificates
.PHONY: certs
certs: check-mkcert ## Generate SSL certificates with mkcert
	@echo "$(YELLOW)Generating SSL certificates...$(NC)"
	@mkdir -p $(CERT_DIR)
	@cd $(CERT_DIR) && mkcert $(DOMAINS)
	@cd $(CERT_DIR) && (mv app.pk+4.pem app.pk.pem 2>/dev/null || mv app.pk+*.pem app.pk.pem)
	@cd $(CERT_DIR) && (mv app.pk+4-key.pem app.pk-key.pem 2>/dev/null || mv app.pk+*-key.pem app.pk-key.pem)
	@echo "$(GREEN)Certificates generated successfully!$(NC)"
	@$(MAKE) check-certs

# Check certificate expiration
.PHONY: check-certs
check-certs: ## Check certificate expiration date
	@if [ -f "$(CERT_FILE)" ]; then \
		echo "$(YELLOW)Certificate information:$(NC)"; \
		echo -n "  Expires on: "; \
		openssl x509 -in $(CERT_FILE) -noout -enddate | cut -d= -f2; \
		DAYS=$$(openssl x509 -in $(CERT_FILE) -noout -checkend 86400 2>/dev/null && echo "999" || \
			openssl x509 -in $(CERT_FILE) -noout -checkend 2592000 2>/dev/null && echo "30" || echo "0"); \
		if [ "$$DAYS" = "999" ]; then \
			echo "$(GREEN)  Certificate is valid for more than 30 days$(NC)"; \
		elif [ "$$DAYS" = "30" ]; then \
			echo "$(YELLOW)  Certificate expires within 30 days!$(NC)"; \
		else \
			echo "$(RED)  Certificate expires soon or is invalid!$(NC)"; \
		fi; \
	else \
		echo "$(RED)Certificate not found! Run 'make certs' to generate.$(NC)"; \
		exit 1; \
	fi

# Renew certificates (force regeneration)
.PHONY: renew-certs
renew-certs: ## Force renew certificates and reload nginx
	@echo "$(YELLOW)Renewing certificates...$(NC)"
	@rm -f $(CERT_FILE) $(CERT_KEY)
	@$(MAKE) certs
	@if [ $$($(DOCKER_COMPOSE) ps -q nginx-web) ]; then \
		echo "$(YELLOW)Reloading nginx...$(NC)"; \
		$(DOCKER_COMPOSE) exec nginx-web nginx -s reload; \
		echo "$(GREEN)Nginx reloaded with new certificates!$(NC)"; \
	else \
		echo "$(YELLOW)Nginx not running. Start with 'make start'$(NC)"; \
	fi

# Docker commands
.PHONY: build
build: ## Build Docker containers
	@echo "$(YELLOW)Building Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build complete!$(NC)"

.PHONY: start
start: check-certs ## Start all Docker containers
	@echo "$(YELLOW)Starting Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Containers started!$(NC)"
	@$(MAKE) status

.PHONY: stop
stop: ## Stop all Docker containers
	@echo "$(YELLOW)Stopping Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) stop
	@echo "$(GREEN)Containers stopped!$(NC)"

.PHONY: down
down: ## Stop and remove Docker containers
	@echo "$(YELLOW)Removing Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Containers removed!$(NC)"

.PHONY: restart
restart: ## Restart all Docker containers
	@echo "$(YELLOW)Restarting Docker containers...$(NC)"
	@$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)Containers restarted!$(NC)"
	@$(MAKE) status

.PHONY: status
status: ## Show status of Docker containers
	@echo "$(YELLOW)Container status:$(NC)"
	@$(DOCKER_COMPOSE) ps

.PHONY: logs
logs: ## Show Docker logs (all services)
	@$(DOCKER_COMPOSE) logs -f

.PHONY: logs-nginx
logs-nginx: ## Show nginx logs
	@$(DOCKER_COMPOSE) logs -f nginx-web

.PHONY: logs-php
logs-php: ## Show PHP logs
	@$(DOCKER_COMPOSE) logs -f webserver

.PHONY: nginx-test
nginx-test: ## Test nginx configuration
	@echo "$(YELLOW)Testing nginx configuration...$(NC)"
	@$(DOCKER_COMPOSE) exec nginx-web nginx -t

.PHONY: nginx-reload
nginx-reload: ## Reload nginx configuration
	@echo "$(YELLOW)Reloading nginx...$(NC)"
	@$(DOCKER_COMPOSE) exec nginx-web nginx -s reload
	@echo "$(GREEN)Nginx reloaded!$(NC)"

# Shell access
.PHONY: shell-nginx
shell-nginx: ## Open bash shell in nginx container
	@$(DOCKER_COMPOSE) exec nginx-web /bin/bash

.PHONY: shell-php
shell-php: ## Open bash shell in PHP container
	@$(DOCKER_COMPOSE) exec webserver /bin/bash

.PHONY: shell-mysql
shell-mysql: ## Open MySQL CLI
	@$(DOCKER_COMPOSE) exec mysql mysql -uroot -ptiger

# Clean commands
.PHONY: clean
clean: ## Remove certificates and Docker volumes (preserves data)
	@echo "$(RED)Warning: This will remove certificates and Docker containers!$(NC)"
	@read -p "Are you sure? [y/N]: " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(MAKE) down; \
		rm -rf $(CERT_DIR); \
		echo "$(GREEN)Cleaned!$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

.PHONY: clean-all
clean-all: ## Remove everything including MySQL data (DANGEROUS!)
	@echo "$(RED)WARNING: This will DELETE all data including MySQL databases!$(NC)"
	@read -p "Are you REALLY sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(MAKE) down; \
		rm -rf $(CERT_DIR); \
		rm -rf ./data; \
		rm -rf ./logs; \
		$(DOCKER_COMPOSE) down -v; \
		echo "$(GREEN)Everything cleaned!$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

# Development workflow
.PHONY: dev
dev: check-certs start ## Start development environment
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "$(YELLOW)Access your site at:$(NC)"
	@echo "  $(GREEN)https://app.pk$(NC)"
	@echo "  $(GREEN)https://www.app.pk$(NC)"
	@echo "  $(GREEN)http://localhost:9090$(NC) (phpMyAdmin)"
	@echo ""
	@echo "$(YELLOW)Useful commands:$(NC)"
	@echo "  make logs        - View all logs"
	@echo "  make status      - Check container status"
	@echo "  make shell-php   - Open PHP container shell"
	@echo "  make stop        - Stop containers"

.PHONY: fresh
fresh: clean install dev ## Fresh installation (remove everything and start over)
	@echo "$(GREEN)Fresh installation complete!$(NC)"

# Validation
.PHONY: validate
validate: ## Validate the entire setup
	@echo "$(YELLOW)Validating setup...$(NC)"
	@echo -n "✓ Checking mkcert... "
	@command -v mkcert >/dev/null 2>&1 && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)"
	@echo -n "✓ Checking certificates... "
	@[ -f "$(CERT_FILE)" ] && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)"
	@echo -n "✓ Checking /etc/hosts... "
	@grep -q "app.pk" /etc/hosts && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)"
	@echo -n "✓ Checking Docker... "
	@docker info >/dev/null 2>&1 && echo "$(GREEN)OK$(NC)" || echo "$(RED)NOT RUNNING$(NC)"
	@echo -n "✓ Checking docker-compose... "
	@command -v docker-compose >/dev/null 2>&1 && echo "$(GREEN)OK$(NC)" || echo "$(RED)MISSING$(NC)"
	@echo "$(GREEN)Validation complete!$(NC)"

# Quick access URLs
.PHONY: urls
urls: ## Show all accessible URLs
	@echo "$(YELLOW)Available URLs:$(NC)"
	@echo "  $(GREEN)https://app.pk$(NC) - Main application"
	@echo "  $(GREEN)https://www.app.pk$(NC) - WWW subdomain"
	@echo "  $(GREEN)http://localhost:9090$(NC) - phpMyAdmin"
	@echo "  $(GREEN)http://localhost:9200$(NC) - Elasticsearch"
	@echo "  $(GREEN)http://localhost:8025$(NC) - MailHog"