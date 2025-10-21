# PowerShell скрипт для быстрой проверки RBAC
# Запуск: .\quick_test.ps1

Write-Host "=== Быстрая проверка RBAC ===" -ForegroundColor Green
Write-Host ""

# Функция для быстрого теста пользователя
function Test-UserQuick {
    param(
        [string]$username,
        [string]$description
    )
    
    $context = "${username}-context"
    Write-Host "--- $description ($username) ---" -ForegroundColor Cyan
    
    # Переключаемся на контекст пользователя
    kubectl config use-context $context 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Контекст $context не найден" -ForegroundColor Red
        return
    }
    
    # Тест просмотра
    Write-Host -NoNewline "  Просмотр pods: "
    kubectl get pods --all-namespaces >$null 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "✓" -ForegroundColor Green } else { Write-Host "✗" -ForegroundColor Red }
    
    # Тест создания в development
    Write-Host -NoNewline "  Создание в development: "
    $result = kubectl auth can-i create pods --namespace=development 2>$null
    if ($result -eq "yes") { Write-Host "✓" -ForegroundColor Green } else { Write-Host "✗" -ForegroundColor Red }
    
    # Тест создания в production  
    Write-Host -NoNewline "  Создание в production: "
    $result = kubectl auth can-i create pods --namespace=production 2>$null
    if ($result -eq "yes") { Write-Host "✓" -ForegroundColor Green } else { Write-Host "✗" -ForegroundColor Red }
    
    # Тест просмотра секретов
    Write-Host -NoNewline "  Просмотр secrets: "
    $result = kubectl auth can-i get secrets --all-namespaces 2>$null
    if ($result -eq "yes") { Write-Host "✓" -ForegroundColor Green } else { Write-Host "✗" -ForegroundColor Red }
    
    Write-Host ""
}

Write-Host "Проверяем основные роли..." -ForegroundColor Yellow
Write-Host ""

# Тестируем каждого пользователя
Test-UserQuick "admin1" "Администратор"
Test-UserQuick "devops1" "DevOps оператор"  
Test-UserQuick "dev1" "Разработчик"
Test-UserQuick "lead1" "Лид команды"
Test-UserQuick "analyst1" "Аналитик"

# Возвращаемся к admin контексту
kubectl config use-context minikube

Write-Host "=== Результаты ===" -ForegroundColor Green
Write-Host "✓ - пользователь имеет право" -ForegroundColor Green
Write-Host "✗ - пользователь НЕ имеет права" -ForegroundColor Red
Write-Host ""
Write-Host "Для детальной проверки запустите: .\verify_rbac.ps1" -ForegroundColor Yellow
