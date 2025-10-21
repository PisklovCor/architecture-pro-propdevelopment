#!/bin/bash

# Скрипт для связывания пользователей с ролями через ClusterRoleBinding и RoleBinding
# Этот скрипт создает привязки пользователей к соответствующим ролям

set -e

echo "=== Создание ClusterRoleBindings для администраторов ==="

# 1. Администраторы кластера - полный доступ
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admins-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin-custom
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin2
EOF

echo "=== Создание ClusterRoleBindings для операторов ==="

# 2. DevOps операторы - операционное управление
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-operators-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-operator
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops2
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops3
EOF

echo "=== Создание ClusterRoleBindings для наблюдателей ==="

# 3. Аналитики - только просмотр
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: analysts-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-viewer
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: analyst1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: analyst2
EOF

echo "=== Создание RoleBindings для лидов команд ==="

# 4. Лиды команд - администраторы namespace
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-leads-development
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead2
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-leads-production
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead2
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-leads-testing
  namespace: testing
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead2
EOF

echo "=== Создание RoleBindings для разработчиков ==="

# 5. Разработчики - доступ к namespace для разработки
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-development
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-developer
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev2
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev3
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev4
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev5
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-testing
  namespace: testing
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-developer
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev2
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev3
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev4
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev5
EOF

echo "=== Создание дополнительных привязок для DevOps операторов ==="

# DevOps операторы также получают права администратора namespace в production
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-production-admin
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops2
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops3
EOF

echo "=== Создание привязок завершено ==="
echo ""
echo "Созданы следующие привязки:"
echo "1. ClusterRoleBindings:"
echo "   - cluster-admins-binding (admin1, admin2) -> cluster-admin-custom"
echo "   - devops-operators-binding (devops1-3) -> cluster-operator"
echo "   - analysts-binding (analyst1-2) -> cluster-viewer"
echo ""
echo "2. RoleBindings:"
echo "   - team-leads-* (lead1-2) -> namespace-admin в development/production/testing"
echo "   - developers-* (dev1-5) -> namespace-developer в development/testing"
echo "   - devops-production-admin (devops1-3) -> namespace-admin в production"
echo ""
echo "Проверить права пользователя можно командой:"
echo "kubectl auth can-i <verb> <resource> --as=<username>"

