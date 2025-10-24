#!/bin/bash

set -e

echo "=== Запуск Minikube с аудитом ==="

# Останавливаем если запущен
if minikube status &>/dev/null 2>&1; then
    echo "Останавливаем Minikube..."
    minikube stop
    minikube delete
fi

# Создаем директорию для политики аудита
AUDIT_DIR="$HOME/.minikube/files/etc/ssl/certs"
mkdir -p "$AUDIT_DIR"

# Создаем ИСПРАВЛЕННЫЙ файл политики аудита
cat > "$AUDIT_DIR/audit-policy.yaml" <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: RequestResponse
    verbs: ["create", "delete", "update", "patch", "get", "list"]
    resources:
      - group: ""
        resources: ["pods", "secrets", "configmaps", "serviceaccounts", "roles", "rolebindings"]
  - level: Metadata
    resources:
      - group: ""
        resources: ["*"]
EOF

echo "✓ Политика аудита создана: $AUDIT_DIR/audit-policy.yaml"

# Запускаем Minikube с аудитом
# ВАЖНО: используем //- чтобы Git Bash не конвертировал путь
echo "Запуск Minikube с аудитом..."
MSYS_NO_PATHCONV=1 minikube start \
    --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml \
    --extra-config=apiserver.audit-log-path=//- \
    --driver=docker

echo ""
echo "=== Minikube успешно запущен с аудитом! ==="
echo ""
echo "Статус кластера:"
minikube status

echo ""
echo "=== Команды для работы с логами аудита ==="
echo ""
echo "Просмотр логов аудита в файле:"
echo "  kubectl logs kube-apiserver-minikube -n kube-system > audit.log"
echo ""