#!/bin/bash

# Скрипт для применения сетевых политик

echo "Применение сетевых политик..."

# Проверяем, что namespace существует
if ! kubectl get namespace network-policy-test >/dev/null 2>&1; then
    echo "ОШИБКА: Namespace 'network-policy-test' не найден!"
    echo "Сначала запустите deploy_services.sh"
    exit 1
fi

# Применяем сетевые политики
echo "Применение файла non-admin-api-allow.yaml..."
kubectl apply -f non-admin-api-allow.yaml

if [ $? -eq 0 ]; then
    echo "✅ Сетевые политики успешно применены!"
    echo ""
    echo "Созданные политики:"
    kubectl get networkpolicies -n network-policy-test
    echo ""
    echo "Для тестирования запустите: ./test_network_policies.sh"
else
    echo "❌ Ошибка при применении сетевых политик"
    exit 1
fi
