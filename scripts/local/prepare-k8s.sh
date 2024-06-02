#!/bin/bash

if [ -f ./scripts/local/.env.local ]; then
  set -o allexport
  source ./scripts/local/.env.local
  set +o allexport
else
  echo ".env.local file not found"
  exit 1
fi

set -u # or set -o nounset
: "$JWT_KEY"
: "$STRIPE_KEY"

kubectl delete secret stripe-secret
kubectl delete secret jwt-secret
kubectl create secret generic stripe-secret --from-literal=STRIPE_KEY=$STRIPE_KEY
kubectl create secret generic jwt-secret --from-literal=JWT_KEY=$JWT_KEY

# Temporary directory for the processed manifests
GENERATED_DIR=./scripts/local/k8s-generated
rm -rf $GENERATED_DIR
mkdir $GENERATED_DIR

# Process each manifest
for file in ./scripts/k8s/* ./scripts/k8s-dev/*; do
  envsubst < "$file" > "$GENERATED_DIR/$(basename "$file")"
done