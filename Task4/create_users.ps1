# PowerShell скрипт для создания пользователей Kubernetes
# Запуск: .\create_users.ps1

Write-Host "=== Создание пользователей Kubernetes ===" -ForegroundColor Green

# Создаем директорию для сертификатов
New-Item -ItemType Directory -Force -Path ".\certs\users" | Out-Null

# Функция для создания сертификата пользователя
function Create-UserCert {
    param(
        [string]$username,
        [string]$group
    )
    
    Write-Host "Создание сертификата для пользователя: $username" -ForegroundColor Yellow
    
    # Проверяем наличие OpenSSL
    if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
        Write-Host "Ошибка: OpenSSL не найден. Установите Git for Windows или WSL" -ForegroundColor Red
        return
    }
    
    # Создаем приватный ключ
    & openssl genrsa -out ".\certs\users\$username.key" 2048
    
    # Создаем запрос на сертификат
    & openssl req -new -key ".\certs\users\$username.key" -out ".\certs\users\$username.csr" -subj "/CN=$username/O=$group"
    
    # Подписываем сертификат с помощью CA кластера
    $minikubePath = "$env:USERPROFILE\.minikube"
    & openssl x509 -req -in ".\certs\users\$username.csr" -CA "$minikubePath\ca.crt" -CAkey "$minikubePath\ca.key" -CAcreateserial -out ".\certs\users\$username.crt" -days 365
    
    # Создаем kubeconfig для пользователя
    kubectl config set-credentials $username --client-certificate=".\certs\users\$username.crt" --client-key=".\certs\users\$username.key" --embed-certs=true
    
    Write-Host "Пользователь $username создан успешно" -ForegroundColor Green
}

# Создаем пользователей для каждой группы
Write-Host "=== Создание администраторов кластера ===" -ForegroundColor Cyan
Create-UserCert "admin1" "cluster-admins"
Create-UserCert "admin2" "cluster-admins"

Write-Host "=== Создание DevOps операторов ===" -ForegroundColor Cyan
Create-UserCert "devops1" "devops-operators"
Create-UserCert "devops2" "devops-operators"
Create-UserCert "devops3" "devops-operators"

Write-Host "=== Создание разработчиков ===" -ForegroundColor Cyan
Create-UserCert "dev1" "developers"
Create-UserCert "dev2" "developers"
Create-UserCert "dev3" "developers"
Create-UserCert "dev4" "developers"
Create-UserCert "dev5" "developers"

Write-Host "=== Создание лидов команд ===" -ForegroundColor Cyan
Create-UserCert "lead1" "team-leads"
Create-UserCert "lead2" "team-leads"

Write-Host "=== Создание аналитиков ===" -ForegroundColor Cyan
Create-UserCert "analyst1" "analysts"
Create-UserCert "analyst2" "analysts"

Write-Host "=== Создание контекстов для пользователей ===" -ForegroundColor Cyan

# Создаем контексты для каждого пользователя
$users = @("admin1", "admin2", "devops1", "devops2", "devops3", "dev1", "dev2", "dev3", "dev4", "dev5", "lead1", "lead2", "analyst1", "analyst2")

foreach ($user in $users) {
    kubectl config set-context "${user}-context" --cluster=minikube --user=$user
    Write-Host "Контекст ${user}-context создан" -ForegroundColor Green
}

Write-Host "=== Создание пользователей завершено ===" -ForegroundColor Green
Write-Host "Всего создано пользователей: 14" -ForegroundColor White
Write-Host "Сертификаты сохранены в директории: .\certs\users\" -ForegroundColor White
Write-Host ""
Write-Host "Для переключения на пользователя используйте:" -ForegroundColor Yellow
Write-Host "kubectl config use-context <username>-context" -ForegroundColor Yellow
