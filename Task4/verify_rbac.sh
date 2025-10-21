#!/bin/bash

# Скрипт для проверки корректности работы RBAC в Kubernetes
# Этот скрипт проверяет права доступа для всех созданных пользователей

set -e

echo "=== Проверка RBAC настроек ==="
echo ""

# Функция для проверки прав пользователя
check_user_permissions() {
    local username=$1
    local context="${username}-context"
    
    echo "--- Проверка прав пользователя: $username ---"
    
    # Переключаемся на контекст пользователя
    kubectl config use-context $context
    
    # Проверяем базовые права
    echo "Проверка просмотра pods:"
    kubectl get pods --all-namespaces 2>/dev/null && echo "✓ Успешно" || echo "✗ Ошибка"
    
    echo "Проверка просмотра services:"
    kubectl get services --all-namespaces 2>/dev/null && echo "✓ Успешно" || echo "✗ Ошибка"
    
    echo "Проверка просмотра secrets:"
    kubectl get secrets --all-namespaces 2>/dev/null && echo "✓ Успешно" || echo "✗ Ошибка"
    
    echo "Проверка создания pod в development:"
    kubectl run test-pod-$username --image=nginx --namespace=development --dry-run=client 2>/dev/null && echo "✓ Успешно" || echo "✗ Ошибка"
    
    echo "Проверка удаления pod в development:"
    kubectl delete pod test-pod-$username --namespace=development --dry-run=client 2>/dev/null && echo "✓ Успешно" || echo "✗ Ошибка"
    
    echo ""
}

# Функция для детальной проверки конкретных прав
check_specific_permissions() {
    local username=$1
    local context="${username}-context"
    
    echo "--- Детальная проверка прав для: $username ---"
    
    kubectl config use-context $context
    
    # Проверяем права через kubectl auth can-i
    echo "Проверка через kubectl auth can-i:"
    
    # Базовые права просмотра
    echo -n "  Просмотр pods: "
    kubectl auth can-i get pods --all-namespaces 2>/dev/null && echo "✓" || echo "✗"
    
    echo -n "  Просмотр services: "
    kubectl auth can-i get services --all-namespaces 2>/dev/null && echo "✓" || echo "✗"
    
    echo -n "  Просмотр secrets: "
    kubectl auth can-i get secrets --all-namespaces 2>/dev/null && echo "✓" || echo "✗"
    
    # Права создания
    echo -n "  Создание pods в development: "
    kubectl auth can-i create pods --namespace=development 2>/dev/null && echo "✓" || echo "✗"
    
    echo -n "  Создание deployments в development: "
    kubectl auth can-i create deployments --namespace=development 2>/dev/null && echo "✓" || echo "✗"
    
    # Права удаления
    echo -n "  Удаление pods в development: "
    kubectl auth can-i delete pods --namespace=development 2>/dev/null && echo "✓" || echo "✗"
    
    # Права в production
    echo -n "  Создание pods в production: "
    kubectl auth can-i create pods --namespace=production 2>/dev/null && echo "✓" || echo "✗"
    
    # Права в testing
    echo -n "  Создание pods в testing: "
    kubectl auth can-i create pods --namespace=testing 2>/dev/null && echo "✓" || echo "✗"
    
    echo ""
}

# Функция для проверки ролей и привязок
check_roles_and_bindings() {
    echo "--- Проверка созданных ролей и привязок ---"
    
    # Возвращаемся к admin контексту
    kubectl config use-context minikube
    
    echo "ClusterRoles:"
    kubectl get clusterroles | grep -E "(cluster-admin-custom|cluster-operator|cluster-viewer|namespace-admin|namespace-developer)"
    
    echo ""
    echo "ClusterRoleBindings:"
    kubectl get clusterrolebindings | grep -E "(cluster-admins-binding|devops-operators-binding|analysts-binding)"
    
    echo ""
    echo "RoleBindings:"
    kubectl get rolebindings --all-namespaces | grep -E "(team-leads|developers|devops)"
    
    echo ""
}

# Функция для тестирования конкретных сценариев
test_scenarios() {
    echo "--- Тестирование сценариев использования ---"
    
    # Тест 1: Администратор должен иметь полный доступ
    echo "Тест 1: Администратор (admin1) - полный доступ"
    kubectl config use-context admin1-context
    kubectl auth can-i "*" "*" --all-namespaces 2>/dev/null && echo "✓ Админ имеет полный доступ" || echo "✗ Ошибка доступа"
    
    # Тест 2: Аналитик не должен создавать ресурсы
    echo "Тест 2: Аналитик (analyst1) - только просмотр"
    kubectl config use-context analyst1-context
    kubectl auth can-i create pods --namespace=development 2>/dev/null && echo "✗ Аналитик не должен создавать" || echo "✓ Аналитик не может создавать"
    
    # Тест 3: Разработчик должен создавать в development
    echo "Тест 3: Разработчик (dev1) - создание в development"
    kubectl config use-context dev1-context
    kubectl auth can-i create pods --namespace=development 2>/dev/null && echo "✓ Разработчик может создавать в development" || echo "✗ Ошибка доступа"
    
    # Тест 4: Разработчик не должен создавать в production
    echo "Тест 4: Разработчик (dev1) - НЕ должен создавать в production"
    kubectl auth can-i create pods --namespace=production 2>/dev/null && echo "✗ Разработчик не должен создавать в production" || echo "✓ Разработчик не может создавать в production"
    
    # Тест 5: DevOps оператор должен управлять в production
    echo "Тест 5: DevOps оператор (devops1) - управление в production"
    kubectl config use-context devops1-context
    kubectl auth can-i create pods --namespace=production 2>/dev/null && echo "✓ DevOps может управлять в production" || echo "✗ Ошибка доступа"
    
    echo ""
}

# Функция для проверки namespace
check_namespaces() {
    echo "--- Проверка namespace ---"
    
    kubectl config use-context minikube
    
    echo "Созданные namespace:"
    kubectl get namespaces | grep -E "(development|production|testing)"
    
    echo ""
}

# Функция для проверки сертификатов пользователей
check_user_certificates() {
    echo "--- Проверка сертификатов пользователей ---"
    
    if [ -d "./certs/users" ]; then
        echo "Сертификаты пользователей:"
        ls -la ./certs/users/*.crt 2>/dev/null | wc -l | xargs echo "Количество сертификатов:"
        echo ""
    else
        echo "✗ Директория с сертификатами не найдена"
        echo ""
    fi
}

# Основная функция проверки
main() {
    echo "=== Комплексная проверка RBAC настроек ==="
    echo ""
    
    # Проверяем что мы в кластере
    if ! kubectl cluster-info >/dev/null 2>&1; then
        echo "✗ Ошибка: не удается подключиться к кластеру Kubernetes"
        echo "Убедитесь что Minikube запущен: minikube start"
        exit 1
    fi
    
    # Выполняем все проверки
    check_user_certificates
    check_namespaces
    check_roles_and_bindings
    
    # Проверяем права для каждого типа пользователя
    echo "=== Проверка прав пользователей ==="
    
    # Администраторы
    check_specific_permissions "admin1"
    
    # DevOps операторы  
    check_specific_permissions "devops1"
    
    # Разработчики
    check_specific_permissions "dev1"
    
    # Лиды команд
    check_specific_permissions "lead1"
    
    # Аналитики
    check_specific_permissions "analyst1"
    
    # Тестируем сценарии
    test_scenarios
    
    # Возвращаемся к admin контексту
    kubectl config use-context minikube
    
    echo "=== Проверка завершена ==="
    echo ""
    echo "Для детальной проверки конкретного пользователя используйте:"
    echo "kubectl config use-context <username>-context"
    echo "kubectl auth can-i <verb> <resource> --namespace=<namespace>"
}

# Запускаем проверку
main
