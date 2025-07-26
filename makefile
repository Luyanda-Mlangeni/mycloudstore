.PHONY: dev build run migrate-up migrate-down migrate-create docker-up docker-down

# Load environment variables from .env file
include .env
export

# Build database URL from environment variables
DB_URL := postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable

# Development workflow
dev: docker-up migrate-up
	go run backend/main.go

# Build
build:
	go build -o bin/mycloudstore backend/main.go

run:
	./bin/mycloudstore

# Database management
docker-up:
	docker-compose up -d postgres
	@echo "Waiting for database to be ready..."
	@sleep 3

docker-down:
	docker-compose down

# Migration commands
migrate-up:
	migrate -path backend/migrations -database "$(DB_URL)" up
	@echo "Migrations applied successfully"

migrate-down:
	migrate -path backend/migrations -database "$(DB_URL)" down 1
	@echo "Last migration rolled back"

migrate-create:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir backend/migrations $$name

# Show current database URL (for debugging)
show-db-url:
	@echo "Database URL: $(DB_URL)"

# Dependencies
deps:
	go mod download
	go mod tidy
	@which migrate > /dev/null || (echo "Installing migrate tool..." && go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest)

# Clean
clean:
	rm -rf bin/
	docker-compose down -v