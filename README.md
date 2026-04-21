Author: Air
Hello this is the start of the COMP7370 PROJECT

Chains Chain 1: chain1-b2-token-automount-disabled 

# Commands to get cluster in Chain1 B2 state Tokenautomount disabled state

# 1. Restore broad RBAC on paper
kubectl apply -f /home/ubuntu/COMP7370/manifests/rbac/bad-rbac.yaml

# 2. Prove broad RBAC exists
kubectl get clusterrole bad-role -o yaml
kubectl get clusterrolebinding bad-role-binding -o yaml

# 3. Recreate attacker pod using B2 pod manifest
kubectl delete pod attacker-pod -n attacker --ignore-not-found
kubectl apply -f manifests/attacker/attacker-pod.yaml
kubectl get pod attacker-pod -n attacker -w

# Press Ctrl+C once pod is Running

# 4. Prove B2 pod config is active
kubectl get pod attacker-pod -n attacker -o yaml

# 5. Prove token is absent
kubectl exec -n attacker attacker-pod -- sh -c 'test -f /var/run/secrets/kubernetes.io/serviceaccount/token && echo TOKEN_PRESENT || echo TOKEN_ABSENT'

# 6. Prove service account credential directory is absent
kubectl exec -n attacker attacker-pod -- ls -l /var/run/secrets/kubernetes.io/serviceaccount

# 7. Prove secret access fails from pod context
kubectl exec -n attacker attacker-pod -- kubectl get secret db-secret -n victim



Hello this is the start of the COMP7370 PROJECT