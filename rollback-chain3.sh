#!/usr/bin/env bash
set -euo pipefail

echo "[*] Rolling back Chain 3 to vulnerable state..."

# Optional: ensure namespace exists
kubectl get ns attacker >/dev/null 2>&1 || kubectl create namespace attacker

# Remove existing host-access pod so spec changes can be reapplied cleanly
kubectl delete pod host-access-pod -n attacker --ignore-not-found=true

# Reapply the vulnerable host access pod
kubectl apply -f manifests/attacker/host-access-pod.yaml

echo "[*] Verifying Chain 3 state..."
kubectl get pods -n attacker
kubectl describe pod host-access-pod -n attacker | sed -n '/Security Context/,+8p'
kubectl describe pod host-access-pod -n attacker | sed -n '/Volumes/,+10p'

echo "[*] Chain 3 rollback complete."
echo "[*] Next manual check:"
echo "    kubectl exec -it host-access-pod -n attacker -- bash"
echo "    ls /host"
