#!/bin/bash
# Robust deploy script for Redmica with DB migration and LDAP config
echo "[INFO] Building custom Redmica image..."
cd "$(dirname "$0")/.."
IMAGE_NAME="redmica-custom:test"
docker build -t "$IMAGE_NAME" .

# Run DB migration before LDAP config
echo "[INFO] Running Redmica DB migration..."
docker run --rm \
  --env-file ../redstone/.env \
  --network=redstone-network \
  -e RAILS_ENV=production \
  -v $(pwd):/app \
  $IMAGE_NAME \
  rails db:migrate

# Run LDAP config script
echo "[INFO] Configuring Redmica LDAP authentication source..."
docker run --rm \
  --env-file ../redstone/.env \
  --network=redstone-network \
  -e RAILS_ENV=production \
  -v $(pwd):/app \
  $IMAGE_NAME \
  rails runner scripts/configure_ldap.rb

# Print run instructions
echo "[INFO] Deploy complete. To run Redmica:"
echo "  docker run --rm -p 3000:3000 --network=redstone-network $IMAGE_NAME"
