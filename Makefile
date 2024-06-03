# Define the default target
.DEFAULT_GOAL := help

# Define variables
APP_MODULE := main:app
APP_PORT := 8080

# Define targets
run:
	.venv/bin/uvicorn $(APP_MODULE) --reload --port $(APP_PORT)

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  run       Start the application using uvicorn"
	@echo "  help      use the command 'make run' to start the application"
.PHONY: help