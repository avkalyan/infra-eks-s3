#!/bin/bash
# Local Kubernetes + AWS S3 Demo Setup
# Provisions in ~30 seconds!

set -e

echo "🚀 Setting up local Kubernetes demo environment..."

# 1. Install k3d if not present
if ! command -v k3d &> /dev/null; then
    echo "📦 Installing k3d..."
    brew install k3d
fi

# 2. Create local k3d cluster (30 seconds)
echo "🎯 Creating k3d cluster..."
k3d cluster create demo-cluster \
    --agents 2 \
    --port "8080:80@loadbalancer" \
    --api-port 6443

# 3. Verify cluster
echo "✅ Verifying cluster..."
kubectl get nodes

# 4. Create S3 bucket (if needed)
echo "📦 Creating S3 bucket..."
BUCKET_NAME="local-k8s-demo-$(date +%s)"
aws s3 mb s3://${BUCKET_NAME} --region us-east-1

# 5. Deploy sample app
echo "🚢 Deploying sample nginx app..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF

echo ""
echo "✅ Demo environment ready!"
echo "🌐 Access app: http://localhost:8080"
echo "📦 S3 Bucket: ${BUCKET_NAME}"
echo ""
echo "To show Kubernetes resources:"
echo "  kubectl get pods"
echo "  kubectl get svc"
echo ""
echo "To cleanup:"
echo "  k3d cluster delete demo-cluster"
echo "  aws s3 rb s3://${BUCKET_NAME} --force"
