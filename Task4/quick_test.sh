#!/bin/bash

# Быстрая проверка RBAC - тестирует основные сценарии
# Используйте этот скрипт для быстрой проверки после настройки

set -e

echo "=== Быстрая проверка RBAC ==="
echo ""

# Функция для быстрого теста пользователя
quick_test_user() {
    local username=$1
    local context="${username}-context"
    local description=$2
    
    echo "--- $description ($username) ---"
    kubectl config use-context $context 2>/dev/null || {
        echo "✗ Контекст $context не найден"
        return
    }
    
    # Тест просмотра
    echo -n "  Просмотр pods: "
    kubectl get pods --all-namespaces >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    # Тест создания в development
    echo -n "  Создание в development: "
    kubectl auth can-i create pods --namespace=development 2>/dev/null && echo "✓" || echo "✗"
    
    # Тест создания в production  
    echo -n "  Создание в production: "
    kubectl auth can-i create pods --namespace=production 2>/dev/null && echo "✓" || echo "✗"
    
    # Тест просмотра секретов
    echo -n "  Просмотр secrets: "
    kubectl auth can-i get secrets --all-namespaces 2>/dev/null && echo "✓" || echo "✗"
    
    echo ""
}

echo "Проверяем основные роли..."
echo ""

# Тестируем каждого пользователя
quick_test_user "admin1" "Администратор"
quick_test_user "devops1" "DevOps оператор"  
quick_test_user "dev1" "Разработчик"
quick_test_user "lead1" "Лид команды"
quick_test_user "analyst1" "Аналитик"

# Возвращаемся к admin контексту
kubectl config use-context minikube

echo "=== Результаты ==="
echo "✓ - пользователь имеет право"
echo "✗ - пользователь НЕ имеет права"
echo ""
echo "Для детальной проверки запустите: ./verify_rbac.sh"
