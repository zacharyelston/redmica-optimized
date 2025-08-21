#!/bin/bash
# Build and tag a custom Redmica Docker image for testing (with RAG/LDAP patches)
set -e
cd "$(dirname "$0")/.."

IMAGE_NAME="redmica-custom:test"

# Load env vars from canonical stack
ENV_FILE="../redstone/.env"
if [ -f "$ENV_FILE" ]; then
  echo "[INFO] Loading env vars from $ENV_FILE"
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "[WARN] $ENV_FILE not found. Proceeding without it."
fi

echo "[INFO] Building custom Redmica image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

echo "[INFO] Build complete. To run:"
echo "  docker run --rm -p 3000:3000 $IMAGE_NAME"

# Automated LDAP configuration (for local/dev/test)
echo "[INFO] Configuring Redmica LDAP authentication source..."
docker run --rm \
  -e RAILS_ENV=production \
  -e LDAP_HOST=redstone-ldap \
  -e LDAP_PORT=1389 \
  -e LDAP_BASE_DN=ou=users,dc=redstone,dc=local \
  -e LDAP_BIND_DN=cn=admin,dc=redstone,dc=local \
  -e LDAP_BIND_PASSWORD=admin \
  -v $(pwd):/app \
  $IMAGE_NAME \
  rails runner scripts/configure_ldap.rb
