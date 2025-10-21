#!/bin/bash

# Скрипт для создания ролей и ClusterRoles в Kubernetes
# Этот скрипт создает все необходимые роли согласно таблице ролей

set -e

echo "=== Создание ClusterRoles ==="

# 1. Cluster Admin Role (используем встроенную роль cluster-admin)
echo "Создание ClusterRole для администраторов кластера..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-custom
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- nonResourceURLs: ["*"]
  verbs: ["*"]
EOF

# 2. Cluster Operator Role
echo "Создание ClusterRole для операторов..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-operator
rules:
# Просмотр всех ресурсов
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "persistentvolumes", "nodes", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
# Управление приложениями
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
# Логи и метрики
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list"]
# НЕ может: секреты, RBAC, системные ресурсы
EOF

# 3. Cluster Viewer Role
echo "Создание ClusterRole для наблюдателей..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-viewer
rules:
# Только просмотр (кроме секретов)
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "persistentvolumes", "nodes", "namespaces", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
# Логи и метрики
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list"]
# НЕ может: создавать, изменять, удалять, просматривать секреты
EOF

# 4. Namespace Admin Role
echo "Создание ClusterRole для администраторов namespace..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-admin
rules:
# Полный доступ к ресурсам в namespace
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
  verbs: ["*"]
- apiGroups: ["extensions"]
  resources: ["deployments", "replicasets"]
  verbs: ["*"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses", "networkpolicies"]
  verbs: ["*"]
# Логи и метрики
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list"]
EOF

# 5. Namespace Developer Role
echo "Создание ClusterRole для разработчиков namespace..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-developer
rules:
# Создание и изменение приложений
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["extensions"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Логи и метрики
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list"]
# НЕ может: удалять ресурсы, просматривать секреты, управлять RBAC
EOF

echo "=== Создание Namespace для тестирования ==="
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace testing --dry-run=client -o yaml | kubectl apply -f -

echo "=== Создание ролей завершено ==="
echo "Созданы следующие ClusterRoles:"
echo "- cluster-admin-custom (полный доступ)"
echo "- cluster-operator (операционное управление)"
echo "- cluster-viewer (только просмотр)"
echo "- namespace-admin (администратор namespace)"
echo "- namespace-developer (разработчик namespace)"
echo ""
echo "Созданы namespace: development, production, testing"
