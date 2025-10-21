#!/bin/bash

# Скрипт для создания пользователей Kubernetes с сертификатной аутентификацией
# Этот скрипт создает пользователей с сертификатами для безопасной аутентификации

set -e

# Создаем директорию для сертификатов
mkdir -p ./certs/users

# Функция для создания сертификата пользователя
create_user_cert() {
    local username=$1
    local group=$2
    
    echo "Создание сертификата для пользователя: $username"
    
    # Создаем приватный ключ
    openssl genrsa -out ./certs/users/${username}.key 2048
    
    # Создаем запрос на сертификат
    openssl req -new -key ./certs/users/${username}.key -out ./certs/users/${username}.csr -subj "/CN=${username}/O=${group}"
    
    # Подписываем сертификат с помощью CA кластера
    openssl x509 -req -in ./certs/users/${username}.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out ./certs/users/${username}.crt -days 365
    
    # Создаем kubeconfig для пользователя
    kubectl config set-credentials ${username} --client-certificate=./certs/users/${username}.crt --client-key=./certs/users/${username}.key --embed-certs=true
    
    echo "Пользователь $username создан успешно"
}

# Создаем пользователей для каждой группы

echo "=== Создание администраторов кластера ==="
create_user_cert "admin1" "cluster-admins"
create_user_cert "admin2" "cluster-admins"

echo "=== Создание DevOps операторов ==="
create_user_cert "devops1" "devops-operators"
create_user_cert "devops2" "devops-operators"
create_user_cert "devops3" "devops-operators"

echo "=== Создание разработчиков ==="
create_user_cert "dev1" "developers"
create_user_cert "dev2" "developers"
create_user_cert "dev3" "developers"
create_user_cert "dev4" "developers"
create_user_cert "dev5" "developers"

echo "=== Создание лидов команд ==="
create_user_cert "lead1" "team-leads"
create_user_cert "lead2" "team-leads"

echo "=== Создание аналитиков ==="
create_user_cert "analyst1" "analysts"
create_user_cert "analyst2" "analysts"

echo "=== Создание контекстов для пользователей ==="

# Создаем контексты для каждого пользователя
for user in admin1 admin2 devops1 devops2 devops3 dev1 dev2 dev3 dev4 dev5 lead1 lead2 analyst1 analyst2; do
    kubectl config set-context ${user}-context --cluster=minikube --user=${user}
    echo "Контекст ${user}-context создан"
done

echo "=== Создание пользователей завершено ==="
echo "Всего создано пользователей: 14"
echo "Сертификаты сохранены в директории: ./certs/users/"
echo ""
echo "Для переключения на пользователя используйте:"
echo "kubectl config use-context <username>-context"
