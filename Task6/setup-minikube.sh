#!/bin/bash

# Скрипт для настройки Minikube с аудитом на Windows

echo "=== Настройка Minikube с аудитом ==="
echo ""

# Проверка наличия minikube
if ! command -v minikube &> /dev/null; then
    echo "Ошибка: minikube не установлен!"
    exit 1
fi

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Ошибка: kubectl не установлен!"
    exit 1
fi

# Проверка наличия файла политики
if [ ! -f "minikube-config/audit-policy.yaml" ]; then
    echo "Ошибка: Файл minikube-config/audit-policy.yaml не найден!"
    echo "Убедитесь, что вы находитесь в директории Task6"
    exit 1
fi

echo "1. Остановка существующего кластера (если есть)..."
minikube stop 2>/dev/null
minikube delete 2>/dev/null
echo ""

echo "2. Создание директорий для аудита на хосте..."
mkdir -p ./minikube-audit/logs
mkdir -p ./minikube-audit/policy

# Копируем политику аудита в локальную директорию
cp minikube-config/audit-policy.yaml ./minikube-audit/policy/

echo "3. Запуск Minikube (сначала без аудита)..."
# Запускаем Minikube без аудита для стабильной инициализации
minikube start --driver=docker

if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось запустить Minikube!"
    exit 1
fi

echo ""
echo "4. Настройка аудита после запуска Minikube..."
echo "   Создаем директории для аудита..."
minikube ssh "sudo mkdir -p /etc/kubernetes/audit-policy /var/log/kubernetes"

echo "   Копируем файл политики аудита..."
minikube ssh "sudo bash -c 'cat > /etc/kubernetes/audit-policy/audit-policy.yaml << \"EOFPOLICY\"
$(cat minikube-config/audit-policy.yaml)
EOFPOLICY
'"
minikube ssh "sudo chmod 644 /etc/kubernetes/audit-policy/audit-policy.yaml"

echo "   Создаем файл лога аудита..."
minikube ssh "sudo touch /var/log/kubernetes/audit.log"
minikube ssh "sudo chmod 666 /var/log/kubernetes/audit.log"

echo "   Настраиваем API server для аудита..."
# Создаем скрипт для настройки API server
minikube ssh 'sudo bash -c "cat > /tmp/setup-audit.sh << '\''EOFSETUP'\''
#!/bin/bash

# Останавливаем API server
pkill -f kube-apiserver

# Ждем завершения
sleep 2

# Запускаем API server с параметрами аудита
/var/lib/minikube/binaries/v1.30.0/kube-apiserver \\
    --advertise-address=192.168.49.2 \\
    --allow-privileged=true \\
    --authorization-mode=Node,RBAC \\
    --client-ca-file=/var/lib/minikube/certs/ca.crt \\
    --enable-admission-plugins=NodeRestriction \\
    --enable-bootstrap-token-auth=true \\
    --etcd-cafile=/var/lib/minikube/certs/etcd/ca.crt \\
    --etcd-certfile=/var/lib/minikube/certs/etcd/server.crt \\
    --etcd-keyfile=/var/lib/minikube/certs/etcd/server.key \\
    --etcd-servers=https://127.0.0.1:2379 \\
    --insecure-port=0 \\
    --kubelet-client-certificate=/var/lib/minikube/certs/apiserver-kubelet-client.crt \\
    --kubelet-client-key=/var/lib/minikube/certs/apiserver-kubelet-client.key \\
    --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \\
    --proxy-client-cert-file=/var/lib/minikube/certs/front-proxy-client.crt \\
    --proxy-client-key-file=/var/lib/minikube/certs/front-proxy-client.key \\
    --requestheader-allowed-names=front-proxy-client \\
    --requestheader-client-ca-file=/var/lib/minikube/certs/front-proxy-ca.crt \\
    --requestheader-extra-headers-prefix=X-Remote-Extra- \\
    --requestheader-group-headers=X-Remote-Group \\
    --requestheader-username-headers=X-Remote-User \\
    --secure-port=8443 \\
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \\
    --service-account-key-file=/var/lib/minikube/certs/sa.pub \\
    --service-account-signing-key-file=/var/lib/minikube/certs/sa.key \\
    --service-cluster-ip-range=10.96.0.0/12 \\
    --tls-cert-file=/var/lib/minikube/certs/apiserver.crt \\
    --tls-private-key-file=/var/lib/minikube/certs/apiserver.key \\
    --audit-policy-file=/etc/kubernetes/audit-policy/audit-policy.yaml \\
    --audit-log-path=/var/log/kubernetes/audit.log \\
    --audit-log-maxage=30 \\
    --audit-log-maxbackup=3 \\
    --audit-log-maxsize=100 \\
    --v=4 > /var/log/kubernetes/apiserver.log 2>&1 &

echo \"API server перезапущен с аудитом\"
EOFSETUP
chmod +x /tmp/setup-audit.sh
/tmp/setup-audit.sh"'

echo "   Ожидание перезапуска API server..."
sleep 10

echo ""
echo "5. Ожидание готовности кластера..."
sleep 10

echo ""
echo "6. Проверка статуса кластера..."
minikube status

echo ""
echo "7. Проверка настроек аудита в API server..."
# Проверяем, что параметры аудита применились
minikube ssh "ps aux | grep kube-apiserver | grep audit" || echo "   ⚠ Параметры аудита не найдены в процессе"

echo ""
echo "8. Проверка файлов аудита..."
# Проверяем, что файлы созданы правильно
minikube ssh "ls -la /etc/kubernetes/audit-policy/" || echo "   ⚠ Директория политики не найдена"
minikube ssh "ls -la /var/log/kubernetes/" || echo "   ⚠ Директория логов не найдена"

echo ""
echo "9. Ожидание инициализации audit logging..."
sleep 5

echo ""
echo "10. Проверка работоспособности кластера..."
kubectl cluster-info

echo ""
echo "11. Проверка, что audit logging работает..."
# Делаем несколько пробных действий
kubectl get nodes > /dev/null 2>&1
kubectl get pods -A > /dev/null 2>&1
sleep 3

# Проверяем лог файл внутри Minikube
LOG_LINES=$(minikube ssh "sudo wc -l /var/log/kubernetes/audit.log 2>/dev/null" | awk '{print $1}' || echo "0")

if [ "$LOG_LINES" -gt 0 ]; then
    echo "   ✓ Audit logging работает! Записей в логе: $LOG_LINES"
    # Показываем пример записи
    echo ""
    echo "   Пример записи из audit.log:"
    minikube ssh "sudo head -1 /var/log/kubernetes/audit.log" | jq -r '"\(.timestamp) \(.verb) \(.objectRef.resource)"' 2>/dev/null || echo "   (лог в формате JSON)"
else
    echo "   ⚠ Предупреждение: audit.log пустой"
    echo "   Это может быть нормально - лог появится после первых операций"
fi

echo ""
echo "=== Настройка завершена ==="
echo ""
echo "Следующие шаги:"
echo "  1. Запустите скрипт симуляции: ./simulate-incident.sh"
echo "  2. Извлеките логи: minikube ssh \"sudo cat /var/log/kubernetes/audit.log\" > audit.log"
echo "  3. Проанализируйте логи: ./analyze_audit.sh audit.log"
echo ""
