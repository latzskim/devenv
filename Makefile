.PHONY: build run dev shell clean help

IMAGE := devenv:latest

build:
	docker build -t $(IMAGE) .

# Common dev-server ports published to the Mac host
DEV_PORTS := -p 127.0.0.1:3000:3000 -p 127.0.0.1:3001:3001 -p 127.0.0.1:4000:4000 -p 127.0.0.1:4173:4173 \
             -p 127.0.0.1:5173:5173 -p 127.0.0.1:8000:8000 -p 127.0.0.1:8080:8080

# Run the container with current directory mounted (ephemeral)
run:
	docker run --rm -it \
		$(DEV_PORTS) \
		-v "$$(pwd):/workspace" \
		-w /workspace \
		-e TERM=xterm-256color \
		$(IMAGE)

# Same as run but start directly in nvim
nvim:
	docker run --rm -it \
		$(DEV_PORTS) \
		-v "$$(pwd):/workspace" \
		-w /workspace \
		-e TERM=xterm-256color \
		$(IMAGE) nvim .

# Use the smart bin/dev script (recommended)
dev:
	@./bin/dev

# Force rebuild + enter
dev-build:
	@./bin/dev --build

shell: run

# Remove dangling images / stopped containers (careful)
clean:
	docker image prune -f
	docker container prune -f

# Remove stopped containers + unused build cache (frees several GB on disk)
clean-all:
	docker container prune -f
	docker image prune -af
	docker builder prune -af

help:
	@echo "devenv Makefile targets:"
	@echo "  make build       - Build the Docker image"
	@echo "  make run         - Shell in current dir"
	@echo "  make nvim        - Directly open nvim in current dir"
	@echo "  make dev         - Use ./bin/dev (best)"
	@echo "  make dev-build   - Rebuild + enter via bin/dev"
	@echo "  make clean       - Prune unused docker objects"
	@echo "  make clean-all   - Aggressive prune (containers, images, build cache)"
