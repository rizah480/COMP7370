Author: Air

Branch: chain2-vuln-no-networkpolicy -> This branch is for keeping the baseline configuration for chain 2. Instructions Below

THESE commands can be ran from the home directory: ~/COMP7370 to get the baseline configuration back:
# Remove Chain 2 policy artifacts
kubectl delete netpol --all -n victim --ignore-not-found
kubectl delete netpol --all -n attacker --ignore-not-found

# Reapply Chain 2 baseline resources
kubectl apply -f manifests/chain2/attacker-sa.yaml
kubectl apply -f manifests/chain2/attacker-pod.yaml
kubectl apply -f manifests/chain2/nginx-deployment.yaml
kubectl apply -f manifests/chain2/nginx-service.yaml

# Wait for victim deployment
kubectl rollout status deployment/nginx -n victim --timeout=60s

# Verify resources
kubectl get netpol -A
kubectl get pods -n attacker -o wide
kubectl get pods -n victim -o wide
kubectl get svc -n victim
kubectl get endpoints -n victim

# Reconfirm baseline reachability
kubectl exec -n attacker attacker-pod -- /bin/sh -c 'curl -I --max-time 5 http://nginx.victim.svc.cluster.local'




Hello this is the start of the COMP7370 PROJECT