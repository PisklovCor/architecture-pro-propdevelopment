#!/bin/bash

# Скрипт для развертывания сервисов с метками в Kubernetes
# Создает 4 пода с соответствующими метками и сервисами

echo "Развертывание сервисов с метками..."

# Создание namespace для изоляции
kubectl create namespace network-policy-test --dry-run=client -o yaml | kubectl apply -f -

# Развертывание front-end сервиса
echo "Создание front-end сервиса..."
kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80 -n network-policy-test

# Развертывание back-end-api сервиса
echo "Создание back-end-api сервиса..."
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80 -n network-policy-test

# Развертывание admin-front-end сервиса
echo "Создание admin-front-end сервиса..."
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80 -n network-policy-test

# Развертывание admin-back-end-api сервиса
echo "Создание admin-back-end-api сервиса..."
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80 -n network-policy-test

echo "Ожидание готовности подов..."
kubectl wait --for=condition=Ready pod -l role=front-end -n network-policy-test --timeout=60s
kubectl wait --for=condition=Ready pod -l role=back-end-api -n network-policy-test --timeout=60s
kubectl wait --for=condition=Ready pod -l role=admin-front-end -n network-policy-test --timeout=60s
kubectl wait --for=condition=Ready pod -l role=admin-back-end-api -n network-policy-test --timeout=60s

echo "Проверка статуса подов:"
kubectl get pods -n network-policy-test -o wide

echo "Проверка сервисов:"
kubectl get services -n network-policy-test

echo "Развертывание сервисов завершено!"
