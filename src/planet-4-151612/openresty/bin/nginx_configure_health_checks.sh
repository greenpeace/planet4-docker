#!/bin/bash
set -euo pipefail

# Configure health checks

f=/etc/nginx/conf.d/40_health-check.conf

dockerize -template "/app/templates$f.tmpl:$f"
