# projectset-signoz
SigNoz Configuration Repository

# Get values.yaml from Helm
helm get values acornworks -n signoz -a -o yaml > values.yaml

# Update values.yaml to k8s
helm upgrade -f values.yaml -n signoz acornworks signoz/signoz

# Patch endpoints
kubectl patch svc acornworks-signoz-frontend -n signoz -p '{"spec": {"type": "LoadBalancer"}}'