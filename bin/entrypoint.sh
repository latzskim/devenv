#!/bin/sh
set -e

# Docker volumes mount as root; ensure the dev user can write caches + deps.
if [ -d /workspace ]; then
	sudo mkdir -p /workspace/.next /workspace/node_modules
	sudo chown -R dev:dev /workspace/.next /workspace/node_modules 2>/dev/null || true
fi

exec "$@"