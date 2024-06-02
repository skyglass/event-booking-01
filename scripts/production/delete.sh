kubectl delete -f ../k8s
kubectl delete -f ../k8s-prod

kubectl delete secret stripe-secret
kubectl delete secret jwt-secret