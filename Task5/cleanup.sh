#!/bin/bash

# Скрипт для очистки созданных ресурсов

NAMESPACE="network-policy-test"

echo "Очистка ресурсов..."

# Удаление сетевых политик
echo "Удаление сетевых политик..."
kubectl delete networkpolicy --all -n $NAMESPACE 2>/dev/null || echo "Сетевые политики не найдены или уже удалены"

# Удаление сервисов
echo "Удаление сервисов..."
kubectl delete service --all -n $NAMESPACE 2>/dev/null || echo "Сервисы не найдены или уже удалены"

# Удаление подов
echo "Удаление подов..."
kubectl delete pod --all -n $NAMESPACE 2>/dev/null || echo "Поды не найдены или уже удалены"

# Удаление namespace
echo "Удаление namespace..."
kubectl delete namespace $NAMESPACE 2>/dev/null || echo "Namespace не найден или уже удален"

echo "Очистка завершена!"
echo "Все ресурсы удалены из namespace: $NAMESPACE"
