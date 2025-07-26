#!/bin/bash

set -e

echo "=== Updating and Installing Base Packages ==="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg apt-transport-https software-properties-common

echo "=== Installing Docker ==="
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "=== Installing Kind ==="
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "=== Creating Kubernetes Cluster with Kind ==="
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

echo "=== Installing Helm ==="
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y

echo "=== Adding Prometheus Helm Repo ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "=== Creating Monitoring Namespace and Installing kube-prometheus-stack ==="
kubectl create namespace monitoring || true
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

echo "=== Waiting for Prometheus and Grafana pods to be ready ==="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s || true

echo "=== Port Forwarding Prometheus (9090) ==="
nohup kubectl port-forward svc/prometheus-stack-kube-prom-prometheus -n monitoring 9090:9090 --address=0.0.0.0 > /dev/null 2>&1 &

echo "=== Port Forwarding Grafana (3000) ==="
nohup kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80 --address=0.0.0.0 > /dev/null 2>&1 &

echo "========================================="
echo "✅ Setup Complete!"
echo "Prometheus: http://<your-ec2-ip>:9090"
echo "Grafana:    http://<your-ec2-ip>:3000"
echo "Grafana Login -> Username: admin | Password: prom-operator"
echo "To import dashboard: https://grafana.com/grafana/dashboards/15661"
echo "========================================="
