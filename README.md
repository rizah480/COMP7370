Hello this is the start of the COMP7370 PROJECT

Chains
Chain 1:
|    Vuln - Branch: aaron
|    Mitigation1 - chain1-b1-rbac-mitigation

## Configure Cluster into Chain 1 B1 State

Chain 1 B1 is the first partial mitigation state for the `Token -> API abuse -> Secrets` chain.

In this state:

- `attacker-pod` still runs as `attacker-sa`
- the ServiceAccount token still remains mounted
- wildcard RBAC is removed
- reduced namespace-scoped RBAC is applied
- limited pod access in the `attacker` namespace still works
- secret access in the `victim` namespace fails

The purpose of this state is to prove that Chain 1 can be interrupted at the **authorization boundary** even when workload identity exposure still exists.

---

### Step 1 — Switch to the B1 branch

```bash
git switch chain1-b1-rbac-mitigation
git status
```

Expected branch:

```text
chain1-b1-rbac-mitigation
```

---

### Step 2 — Remove vulnerable wildcard RBAC

```bash
kubectl delete clusterrolebinding bad-role-binding --ignore-not-found
kubectl delete clusterrole bad-role --ignore-not-found
```

This is required because Kubernetes RBAC is additive. If the old wildcard `ClusterRoleBinding` remains, the reduced B1 RBAC will not actually restrict the attacker identity.

Correct B1 state requires that `bad-role-binding` and `bad-role` are removed.

---

### Step 3 — Apply reduced B1 RBAC

```bash
kubectl apply -f chain1-b1-reduced-rbac.yaml
```

The B1 manifest should define a namespace-scoped `Role` and `RoleBinding` like this:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: attacker
  name: attacker-read-pods-only
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: attacker-sa-read-pods-only
  namespace: attacker
subjects:
- kind: ServiceAccount
  name: attacker-sa
  namespace: attacker
roleRef:
  kind: Role
  name: attacker-read-pods-only
  apiGroup: rbac.authorization.k8s.io
```

This keeps limited pod visibility in the `attacker` namespace while removing secret access from the `victim` namespace.

---

### Step 4 — Confirm only reduced RBAC remains

```bash
kubectl get clusterrolebindings,rolebindings -A | grep attacker-sa
```

Expected B1 output should show only the reduced RoleBinding:

```text
attacker   rolebinding.rbac.authorization.k8s.io/attacker-sa-read-pods-only   Role/attacker-read-pods-only
```

The output should **not** show:

```text
bad-role-binding
```

If `bad-role-binding` still appears, the cluster is not in a clean B1 state.

---

### Step 5 — Confirm attacker pod still uses `attacker-sa`

```bash
kubectl get pod attacker-pod -n attacker -o yaml | grep -E "serviceAccount:|serviceAccountName:|automountServiceAccountToken|kube-api-access|mountPath"
```

Expected evidence:

```text
serviceAccount: attacker-sa
serviceAccountName: attacker-sa
mountPath: /var/run/secrets/kubernetes.io/serviceaccount
```

If `automountServiceAccountToken: false` appears, the cluster is not in B1. That belongs to B2 or the full mitigation state.

---

### Step 6 — Validate B1 authorization from outside the pod

```bash
kubectl auth can-i list pods --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i get pods --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i list secrets --as=system:serviceaccount:attacker:attacker-sa -n victim
kubectl auth can-i get secrets --as=system:serviceaccount:attacker:attacker-sa -n victim
kubectl auth can-i list namespaces --as=system:serviceaccount:attacker:attacker-sa
```

Expected output:

```text
yes
yes
no
no
no
```

Interpretation:

- `yes` for pod access means limited legitimate functionality remains.
- `no` for victim secrets means the authorization boundary has been restored.
- `no` for namespaces means cluster-wide discovery has also been reduced.

---

### Step 7 — Validate B1 from inside the attacker pod

```bash
kubectl exec -it attacker-pod -n attacker -- /bin/sh
```

Inside the pod, run:

```bash
ls -l /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
kubectl auth can-i list pods -n attacker
kubectl auth can-i list secrets -n victim
kubectl auth can-i get secrets -n victim
kubectl get pods -n attacker
kubectl get secrets -n victim
kubectl get secret db-secret -n victim
```

Expected behavior:

```text
token exists
namespace = attacker
list pods in attacker = yes
list secrets in victim = no
get secrets in victim = no
kubectl get pods -n attacker succeeds
kubectl get secrets -n victim fails with Forbidden
kubectl get secret db-secret -n victim fails with Forbidden
```

This proves that the token is still mounted, but reduced RBAC prevents cross-namespace secret access. Therefore, Chain 1 B1 breaks at the authorization boundary.

---

## Quick Reset into Chain 1 B1 State

Use this block when the cluster needs to be forced back into B1:

```bash
git switch chain1-b1-rbac-mitigation

kubectl delete clusterrolebinding bad-role-binding --ignore-not-found
kubectl delete clusterrole bad-role --ignore-not-found

kubectl apply -f chain1-b1-reduced-rbac.yaml
kubectl apply -f /home/ubuntu/COMP7370/manifests/attacker/attacker-pod.yaml

kubectl get clusterrolebindings,rolebindings -A | grep attacker-sa

kubectl auth can-i list pods --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i get pods --as=system:serviceaccount:attacker:attacker-sa -n attacker
kubectl auth can-i list secrets --as=system:serviceaccount:attacker:attacker-sa -n victim
kubectl auth can-i get secrets --as=system:serviceaccount:attacker:attacker-sa -n victim
kubectl auth can-i list namespaces --as=system:serviceaccount:attacker:attacker-sa
```

The last five authorization checks should return:

```text
yes
yes
no
no
no
```

---

## Chain 1 B1 Success Criteria

Chain 1 B1 is successful when:

- The ServiceAccount token is still mounted in `attacker-pod`.
- `attacker-pod` still runs as `attacker-sa`.
- `attacker-sa` can still list/get pods in the `attacker` namespace.
- `attacker-sa` can no longer list/get secrets in the `victim` namespace.
- Direct in-pod attempts to retrieve `victim/db-secret` fail with `Forbidden`.

---

## Chain 1 B1 Interpretation

B1 demonstrates that Chain 1 can be interrupted at the **authorization boundary** even when the workload identity boundary remains exposed.

In other words, the mounted ServiceAccount token is still present, but reduced RBAC prevents the attacker identity from using that token to retrieve sensitive resources.

     
