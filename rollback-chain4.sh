#!/usr/bin/env bash
set -euo pipefail

echo "[*] Rolling back Chain 4 to vulnerable state..."

# Ensure namespaces exist
kubectl get ns attacker >/dev/null 2>&1 || kubectl create namespace attacker
kubectl get ns victim >/dev/null 2>&1 || kubectl create namespace victim

# 1. Remove network segmentation mitigation
kubectl delete -f manifests/network/network-policy.yaml --ignore-not-found=true || true

# 2. Remove any attacker pod so it can be recreated cleanly
kubectl delete pod attacker-pod -n attacker --ignore-not-found=true || true

# 3. Reapply vulnerable RBAC
kubectl apply -f manifests/rbac/bad-rbac.yaml

# 4. Reapply victim workload and service
kubectl apply -f manifests/victim/nginx-deployment.yaml
kubectl apply -f manifests/victim/nginx-service.yaml

# 5. Reapply attacker pod
kubectl apply -f manifests/attacker/attacker-pod.yaml

echo "[*] Waiting briefly for pods/services..."
sleep 5

echo "[*] Verifying Chain 4 state..."
kubectl get pods -n attacker
kubectl get pods -n victim
kubectl get svc -n victim
kubectl get networkpolicy -n victim || true

echo "[*] Chain 4 rollback complete."
echo "[*] Next manual checks:"
echo "    kubectl exec -it attacker-pod -n attacker -- bash"
echo "    curl <victim-cluster-ip>"
echo "    curl <victim-pod-ip>"
