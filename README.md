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

-------------------------------------------------------------------------

# Steps to actually configure pods for chain 2 b1:

kubectl apply -f manifests/chain2/b1-mitigation/chain2-phase1-limited-allow.yaml
kubectl get netpol -n victim
kubectl describe netpol chain2-phase1-limited-allow -n victim
kubectl exec -n attacker attacker-pod -- curl -I --max-time 3 http://10.103.250.84


# Gather evidence for chain 2 b1:
kubectl describe netpol chain2-phase1-limited-allow -n victim 
kubectl get svc -n victim 
kubectl get endpoints -n victim 
kubectl exec -n attacker attacker-pod -- curl -I --max-time 3 http://10.103.250.84

-------------------------------------------------------------------------

# Fully mitigated 

# Steps to configure pods to be in this state
Now reapply the intended B2 set:

kubectl apply -f manifests/chain2/b2-mitigation/victim-default-deny-ingress.yaml
kubectl apply -f manifests/chain2/b2-mitigation/allow-nginx-from-victim-namespace.yaml
# Verify the final state
kubectl get netpol -n victim
kubectl describe netpol victim-default-deny-ingress -n victim
kubectl describe netpol allow-nginx-from-victim-namespace -n victim

# Expected output should show both policies.

# Then validate behavior

# Attacker should fail:

kubectl exec -n attacker attacker-pod -- curl -I --max-time 3 http://nginx.victim.svc.cluster.local

# Service health should still be good:

kubectl get svc -n victim
kubectl get endpoints -n victim
kubectl get pods -n victim -o wide

Optional same-namespace success test:

kubectl run test-client -n victim --rm -it --image=busybox --restart=Never -- sh

Inside that pod:

wget -qO- http://nginx

That should succeed if same-namespace access is allowed correctly.



# Gather Evidence:

kubectl get netpol -n victim
kubectl describe netpol victim-default-deny-ingress -n victim
kubectl describe netpol allow-nginx-from-victim-namespace -n victim
kubectl exec -n attacker attacker-pod -- curl -I --max-time 3 http://nginx.victim.svc.cluster.local
kubectl get svc -n victim
kubectl get endpoints -n victim
kubectl get pods -n victim -o wide

# Screenshot command output when finished














Hello this is the start of the COMP7370 PROJECT