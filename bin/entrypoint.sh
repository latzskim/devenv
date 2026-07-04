#!/bin/sh
set -e

# Docker volumes mount as root; ensure the dev user can write caches.
if [ -d /workspace ]; then
	sudo mkdir -p /workspace/.next
	sudo chown -R dev:dev /workspace/.next 2>/dev/null || true
fi

exec "$@"