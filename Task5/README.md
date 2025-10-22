# Task5: Управление трафиком внутри кластера Kubernetes

Этот набор скриптов реализует задание по настройке сетевых политик в Kubernetes для изоляции трафика между сервисами.

## Структура файлов

- `deploy_services.sh` - Развертывание 4 сервисов с метками
- `non-admin-api-allow.yaml` - Сетевые политики для изоляции трафика
- `apply_network_policies.sh` - Применение сетевых политик
- `test_network_policies.sh` - Тестирование сетевых политик
- `cleanup.sh` - Очистка всех созданных ресурсов

## Порядок выполнения

1. **Развертывание сервисов:**
   ```bash
   chmod +x deploy_services.sh
   ./deploy_services.sh
   ```

2. **Применение сетевых политик:**
   ```bash
   chmod +x apply_network_policies.sh
   ./apply_network_policies.sh
   ```

3. **Тестирование:**
   ```bash
   chmod +x test_network_policies.sh
   ./test_network_policies.sh
   ```

4. **Очистка (после завершения):**
   ```bash
   chmod +x cleanup.sh
   ./cleanup.sh
   ```

## Описание сервисов

Создаются 4 пода с метками:
- `front-end` - Frontend приложение
- `back-end-api` - Backend API
- `admin-front-end` - Админский frontend
- `admin-back-end-api` - Админский backend API

## Сетевые политики

Настроены политики для изоляции трафика:
- `front-end` ↔ `back-end-api` (разрешено)
- `admin-front-end` ↔ `admin-back-end-api` (разрешено)
- Все остальные соединения заблокированы

## Тестирование

Скрипт `test_network_policies.sh` проверяет:
- ✅ Разрешенные подключения работают
- ❌ Заблокированные подключения не работают
