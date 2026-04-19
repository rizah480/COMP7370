#!/usr/bin/env bash
set -euo pipefail

echo "=== Reset Chain 2 to vulnerable baseline ==="

# Ensure script runs from the directory where the script lives.
cd "$(dirname "$0")"

echo
echo "[1] Removing Chain 2 NetworkPolicies"
kubectl delete netpol --all -n victim --ignore-not-found
kubectl delete netpol --all -n attacker --ignore-not-found

echo
echo "[2] Reapplying Chain 2 baseline manifests"
kubectl apply -f manifests/chain2/attacker-sa.yaml

echo
echo "[3] Recreating attacker-pod from baseline manifest"
kubectl delete pod attacker-pod -n attacker --ignore-not-found
kubectl apply -f manifests/chain2/attacker-pod.yaml

echo
echo "[4] Reapplying victim nginx baseline"
kubectl apply -f manifests/chain2/nginx-deployment.yaml
kubectl apply -f manifests/chain2/nginx-service.yaml

echo
echo "[5] Waiting for workloads to become ready"
kubectl rollout status deployment/nginx -n victim --timeout=60s
kubectl wait --for=condition=Ready pod/attacker-pod -n attacker --timeout=60s

echo
echo "[6] Verifying no NetworkPolicies exist"
kubectl get netpol -A

echo
echo "[7] Verifying attacker workload"
kubectl get pods -n attacker -o wide

echo
echo "[8] Verifying victim workload"
kubectl get pods -n victim -o wide

echo
echo "[9] Verifying victim service and endpoint"
kubectl get svc,endpoints -n victim

echo
echo "[10] Verifying vulnerable baseline reachability"
kubectl exec -n attacker attacker-pod -- /bin/sh -c \
  'curl -I --max-time 5 http://nginx.victim.svc.cluster.local'

echo
echo "=== Chain 2 vulnerable baseline reset complete ==="