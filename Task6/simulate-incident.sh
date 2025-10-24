#!/bin/bash

echo "=== Начало симуляции инцидента ==="

# Создание namespace
echo "1. Создание namespace secure-ops..."
kubectl create ns secure-ops
kubectl config set-context --current --namespace=secure-ops

# Создание service account
echo "2. Создание service account monitoring..."
kubectl create sa monitoring

# Создание атакующего пода
echo "3. Создание attacker-pod..."
kubectl run attacker-pod --image=alpine --command -- sleep 3600

# Проверка прав доступа к secrets
echo "4. Проверка прав доступа к secrets..."
kubectl auth can-i get secrets --as=system:serviceaccount:secure-ops:monitoring

# Попытка доступа к secrets в kube-system
echo "5. Попытка доступа к secrets в kube-system..."
SECRET_NAME=$(kubectl get secrets -n kube-system 2>/dev/null | grep default-token | head -n1 | awk '{print $1}')
if [ ! -z "$SECRET_NAME" ]; then
  kubectl get secret -n kube-system $SECRET_NAME --as=system:serviceaccount:secure-ops:monitoring 2>/dev/null || echo "Доступ запрещен (ожидаемо)"
fi

# Создание привилегированного пода
echo "6. Создание привилегированного пода..."
cat <<EOFPOD | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: pwn
    image: alpine
    command: ["sleep", "3600"]
    securityContext:
      privileged: true
  restartPolicy: Never
EOFPOD

# Ожидание запуска пода
sleep 5

# Попытка kubectl exec в чужом поде
echo "7. Попытка kubectl exec в coredns pod..."
COREDNS_POD=$(kubectl get pods -n kube-system 2>/dev/null | grep coredns | awk '{print $1}' | head -n1)
if [ ! -z "$COREDNS_POD" ]; then
  kubectl exec -n kube-system $COREDNS_POD -- cat /etc/resolv.conf 2>/dev/null || echo "Exec выполнен"
fi

# Попытка удаления audit-policy (должна завершиться ошибкой)
echo "8. Попытка удаления audit-policy..."
kubectl delete -f /etc/kubernetes/audit-policy.yaml --as=admin 2>/dev/null || echo "Операция не удалась (файл локальный)"

# Создание опасного RoleBinding
echo "9. Создание RoleBinding с правами cluster-admin..."
cat <<EOFRB | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: escalate-binding
  namespace: secure-ops
subjects:
- kind: ServiceAccount
  name: monitoring
  namespace: secure-ops
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOFRB

echo "=== Симуляция инцидента завершена ==="
