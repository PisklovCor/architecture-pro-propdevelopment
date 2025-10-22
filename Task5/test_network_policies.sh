#!/bin/bash

# Скрипт для тестирования сетевых политик
# Проверяет доступность между сервисами согласно настроенным политикам

NAMESPACE="network-policy-test"

echo "Тестирование сетевых политик..."

# Функция для тестирования подключения
test_connection() {
    local from_pod=$1
    local to_service=$2
    local expected_result=$3
    local test_name=$4
    
    echo "Тест: $test_name"
    echo "От: $from_pod -> К: $to_service"
    
    # Получаем имя пода
    local pod_name=$(kubectl get pods -n $NAMESPACE -l role=$from_pod -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$pod_name" ]; then
        echo "ОШИБКА: Под с ролью $from_pod не найден"
        return 1
    fi
    
    # Тестируем подключение
    local result=$(kubectl exec -n $NAMESPACE $pod_name -- wget -qO- --timeout=5 http://$to_service 2>/dev/null)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ "$expected_result" = "success" ]; then
        echo "✅ УСПЕХ: Подключение работает (как ожидалось)"
    elif [ $exit_code -ne 0 ] && [ "$expected_result" = "fail" ]; then
        echo "✅ УСПЕХ: Подключение заблокировано (как ожидалось)"
    else
        echo "❌ ОШИБКА: Неожиданный результат"
        echo "   Ожидалось: $expected_result, Получено: exit_code=$exit_code"
    fi
    echo "---"
}

echo "Применение сетевых политик..."
kubectl apply -f non-admin-api-allow.yaml

echo "Ожидание применения политик..."
sleep 10

echo "Начинаем тестирование..."
echo "=========================================="

# Тесты для разрешенных подключений
echo "1. Тестирование разрешенных подключений:"
test_connection "front-end" "back-end-api-app" "success" "front-end -> back-end-api"
test_connection "back-end-api" "front-end-app" "success" "back-end-api -> front-end"
test_connection "admin-front-end" "admin-back-end-api-app" "success" "admin-front-end -> admin-back-end-api"
test_connection "admin-back-end-api" "admin-front-end-app" "success" "admin-back-end-api -> admin-front-end"

echo ""
echo "2. Тестирование заблокированных подключений:"
test_connection "front-end" "admin-back-end-api-app" "fail" "front-end -> admin-back-end-api (должно быть заблокировано)"
test_connection "admin-front-end" "back-end-api-app" "fail" "admin-front-end -> back-end-api (должно быть заблокировано)"
test_connection "front-end" "admin-front-end-app" "fail" "front-end -> admin-front-end (должно быть заблокировано)"
test_connection "back-end-api" "admin-back-end-api-app" "fail" "back-end-api -> admin-back-end-api (должно быть заблокировано)"

echo ""
echo "Тестирование завершено!"
echo "Проверьте результаты выше. Разрешенные подключения должны работать, заблокированные - нет."
