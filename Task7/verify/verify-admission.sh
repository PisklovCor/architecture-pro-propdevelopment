#!/bin/bash

echo "=== Проверка работы PodSecurity Admission Controller ==="

# Создаем namespace
echo "1. Создание namespace audit-zone..."
kubectl apply -f ../01-create-namespace.yaml

# Проверяем, что namespace создан
kubectl get namespace audit-zone

echo -e "\n2. Тестирование небезопасных манифестов (должны быть отклонены)..."

# Тест 1: Privileged pod
echo "Тест 1: Попытка создания privileged pod..."
kubectl apply -f ../insecure-manifests/01-privileged-pod.yaml 2>&1 | grep -E "(error|denied|forbidden)" || echo "ОШИБКА: Privileged pod был создан!"

# Тест 2: HostPath pod
echo -e "\nТест 2: Попытка создания pod с hostPath..."
kubectl apply -f ../insecure-manifests/02-hostpath-pod.yaml 2>&1 | grep -E "(error|denied|forbidden)" || echo "ОШИБКА: HostPath pod был создан!"

# Тест 3: Root user pod
echo -e "\nТест 3: Попытка создания pod с root user..."
kubectl apply -f ../insecure-manifests/03-root-user-pod.yaml 2>&1 | grep -E "(error|denied|forbidden)" || echo "ОШИБКА: Root user pod был создан!"

echo -e "\n3. Тестирование безопасных манифестов (должны пройти)..."

# Тест безопасных манифестов
echo "Тест 4: Создание безопасного pod 1..."
kubectl apply -f ../secure-manifests/01-secure.yaml && echo "✓ Безопасный pod 1 создан"

echo "Тест 5: Создание безопасного pod 2..."
kubectl apply -f ../secure-manifests/02-secure.yaml && echo "✓ Безопасный pod 2 создан"

echo "Тест 6: Создание безопасного pod 3..."
kubectl apply -f ../secure-manifests/03-secure.yaml && echo "✓ Безопасный pod 3 создан"

echo -e "\n4. Проверка статуса подов..."
kubectl get pods -n audit-zone

echo -e "\n=== Проверка завершена ==="
