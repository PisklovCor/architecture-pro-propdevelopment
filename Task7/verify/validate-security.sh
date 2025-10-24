#!/bin/bash

echo "=== Валидация политик безопасности ==="

# Проверяем, что Gatekeeper установлен
echo "1. Проверка установки Gatekeeper..."
kubectl get pods -n gatekeeper-system 2>/dev/null || echo "ВНИМАНИЕ: Gatekeeper не установлен"

# Проверяем constraint templates
echo -e "\n2. Проверка Constraint Templates..."
kubectl get constrainttemplates | grep -E "(k8snoPrivileged|k8snoHostPath|k8srunAsNonRoot)"

# Проверяем constraints
echo -e "\n3. Проверка Constraints..."
kubectl get k8snoprivileged,no-privileged-containers 2>/dev/null || echo "Constraint для privileged не найден"
kubectl get k8snohostpath,no-hostpath-volumes 2>/dev/null || echo "Constraint для hostPath не найден"
kubectl get k8srunasnonroot,run-as-non-root 2>/dev/null || echo "Constraint для runAsNonRoot не найден"

# Проверяем статус подов
echo -e "\n4. Статус подов в audit-zone..."
kubectl get pods -n audit-zone -o wide

# Проверяем события
echo -e "\n5. События в namespace audit-zone..."
kubectl get events -n audit-zone --sort-by='.lastTimestamp' | tail -10

# Проверяем логи Gatekeeper
echo -e "\n6. Логи Gatekeeper (последние 10 строк)..."
kubectl logs -n gatekeeper-system -l control-plane=controller-manager --tail=10 2>/dev/null || echo "Логи Gatekeeper недоступны"

echo -e "\n=== Валидация завершена ==="
