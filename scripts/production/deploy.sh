#
# Builds, publishes and deploys all microservices to a production Kubernetes instance.
#
# Usage:
#
#   ./scripts/production/deploy.sh
#

# Source the .env.prod file to load the environment variables
if [ -f .env.prod ]; then
  set -o allexport
  source .env.prod
  set +o allexport
else
  echo ".env.prod file not found"
  exit 1
fi

set -u # or set -o nounset
: "$CONTAINER_REGISTRY"
: "$VERSION"
: "$JWT_KEY"
: "$STRIPE_KEY"

#
# Build Docker images.
#
docker build -t $CONTAINER_REGISTRY/auth:$VERSION --file ../../auth/Dockerfile-prod ../../auth
docker push $CONTAINER_REGISTRY/auth:$VERSION

docker build -t $CONTAINER_REGISTRY/client:$VERSION --file ../../client/Dockerfile-prod ../../client
docker push $CONTAINER_REGISTRY/client:$VERSION

docker build -t $CONTAINER_REGISTRY/expiration:$VERSION --file ../../expiration/Dockerfile-prod ../../expiration
docker push $CONTAINER_REGISTRY/expiration:$VERSION

docker build -t $CONTAINER_REGISTRY/orders:$VERSION --file ../../orders/Dockerfile-prod ../../orders
docker push $CONTAINER_REGISTRY/orders:$VERSION

docker build -t $CONTAINER_REGISTRY/payments:$VERSION --file ../../payments/Dockerfile-prod ../../payments
docker push $CONTAINER_REGISTRY/payments:$VERSION

docker build -t $CONTAINER_REGISTRY/tickets:$VERSION --file ../../tickets/Dockerfile-prod ../../tickets
docker push $CONTAINER_REGISTRY/tickets:$VERSION

# 
# Deploy containers to Kubernetes.
#
# Don't forget to change kubectl to your production Kubernetes instance
#

kubectl delete secret stripe-secret
kubectl delete secret jwt-secret
kubectl create secret generic stripe-secret --from-literal=STRIPE_KEY=$STRIPE_KEY
kubectl create secret generic jwt-secret --from-literal=JWT_KEY=$JWT_KEY

# Temporary directory for the processed manifests
GENERATED_DIR=./k8s-generated
rm -rf $GENERATED_DIR
mkdir $GENERATED_DIR

# Process each manifest
for file in ../k8s/* ../k8s-prod/*; do
  envsubst < "$file" > "$GENERATED_DIR/$(basename "$file")"
done

kubectl apply -f $GENERATED_DIR