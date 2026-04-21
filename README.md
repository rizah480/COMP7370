Author: Air

1. Apply the full mitigation manifest

This applied the hardened ServiceAccount, least-privilege Role, least-privilege RoleBinding, and attempted to apply the hardened Pod:

kubectl apply -f chain1-full-mitigation.yaml

That updated the RBAC-side objects successfully, but the existing pod could not be mutated in place and had to be recreated.

2. Inspect leftover RBAC and identify the old vulnerable binding

These commands were used to discover that the old broad binding still existed and that the cluster was in a mixed state:

kubectl get clusterrolebinding
kubectl get rolebinding -A
kubectl get clusterrole

That is how you confirmed bad-role-binding and bad-role were still present.

3. Inspect duplicate least-privilege bindings

These commands were used to verify that the older attacker-sa-read-pods-only pair and the newer attacker-least-priv-* pair were functionally duplicates:

kubectl get role attacker-read-pods-only -n attacker -o yaml
kubectl get rolebinding attacker-sa-read-pods-only -n attacker -o yaml
kubectl get role attacker-least-priv-role -n attacker -o yaml
kubectl get rolebinding attacker-least-priv-binding -n attacker -o yaml
4. Remove the old vulnerable RBAC and redundant duplicate pair

These are the cleanup commands that were needed to make the full mitigation analytically clean:

kubectl delete clusterrolebinding bad-role-binding
kubectl delete clusterrole bad-role

kubectl delete rolebinding attacker-sa-read-pods-only -n attacker
kubectl delete role attacker-read-pods-only -n attacker

This is the step that actually removed the old over-permissive authorization path.

5. Recreate the attacker pod so pod-level token suppression takes effect

Because the pod spec could not be updated in place, the pod had to be deleted and recreated:

kubectl delete pod attacker-pod -n attacker
kubectl apply -f chain1-full-mitigation.yaml
kubectl get pod attacker-pod -n attacker

This is what moved the workload itself into the hardened state.

6. Validation commands used to prove the cluster was fully mitigated

These are the exact proof commands you ran after cleanup and pod recreation:

kubectl get sa attacker-sa -n attacker -o yaml
kubectl get pod attacker-pod -n attacker -o yaml
kubectl get role attacker-least-priv-role -n attacker -o yaml
kubectl get rolebinding attacker-least-priv-binding -n attacker -o yaml

kubectl exec -n attacker attacker-pod -- sh -c 'test -f /var/run/secrets/kubernetes.io/serviceaccount/token && echo TOKEN_PRESENT || echo TOKEN_ABSENT'
kubectl exec -n attacker attacker-pod -- ls -l /var/run/secrets/kubernetes.io/serviceaccount

kubectl auth can-i get pods --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i list pods --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i get secrets --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i get secrets --as=system:serviceaccount:attacker:attacker-sa -n victim
kubectl auth can-i list secrets --as=system:serviceaccount:attacker:attacker-sa -n victim
kubectl auth can-i '*' '*' --as=system:serviceaccount:attacker:attacker-sa -A

kubectl exec -n attacker attacker-pod -- kubectl get secret db-secret -n victim
kubectl get secret db-secret -n victim --as=system:serviceaccount:attacker:attacker-sa

These commands produced the final evidence that:

token auto-mount was disabled,
the token was absent at runtime,
attacker-sa had only narrow pod-read privileges,
secret access in victim was denied,
and the chain was fully broken.




# To reset back to Vulnerable state:
kubectl apply -f /home/ubuntu/COMP7370/manifests/rbac/bad-rbac.yaml

kubectl get clusterrole bad-role -o yaml
kubectl get clusterrolebinding bad-role-binding -o yaml

kubectl delete pod attacker-pod -n attacker --ignore-not-found
kubectl apply -f manifests/attacker/attacker-pod.yaml
kubectl get pod attacker-pod -n attacker 

kubectl get pod attacker-pod -n attacker -o yaml
kubectl exec -n attacker attacker-pod -- sh -c 'test -f /var/run/secrets/kubernetes.io/serviceaccount/token && echo TOKEN_PRESENT || echo TOKEN_ABSENT'
kubectl exec -n attacker attacker-pod -- ls -l /var/run/secrets/kubernetes.io/serviceaccount
kubectl exec -n attacker attacker-pod -- kubectl get secret db-secret -n victim

Hello this is the start of the COMP7370 PROJECT