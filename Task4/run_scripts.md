# Инструкция по запуску скриптов

## Вариант 1: PowerShell скрипты (рекомендуется для Windows)

1. Откройте PowerShell в директории Task4
2. Запустите PowerShell скрипты:
   ```powershell
   .\create_users.ps1
   .\create_roles.sh
   .\bind_users_roles.sh
   .\quick_test.ps1
   ```

## Вариант 2: Через Git Bash

1. Откройте Git Bash в директории Task4
2. Сделайте скрипты исполняемыми:
   ```bash
   chmod +x *.sh
   ```
3. Запустите скрипты:
   ```bash
   ./create_users.sh
   ./create_roles.sh
   ./bind_users_roles.sh
   ./quick_test.sh
   ```

## Вариант 3: Через WSL (Windows Subsystem for Linux)

1. Откройте WSL в директории проекта
2. Сделайте скрипты исполняемыми:
   ```bash
   chmod +x Task4/*.sh
   ```
3. Запустите скрипты:
   ```bash
   cd Task4
   ./create_users.sh
   ./create_roles.sh
   ./bind_users_roles.sh
   ./quick_test.sh
   ```

## Вариант 4: Через PowerShell (с bash)

1. Установите Git for Windows (включает bash)
2. Откройте PowerShell и выполните:
   ```powershell
   bash Task4/create_users.sh
   bash Task4/create_roles.sh
   bash Task4/bind_users_roles.sh
   bash Task4/quick_test.sh
   ```

## Вариант 5: Через Docker Desktop

Если у вас установлен Docker Desktop с Kubernetes:

1. Включите Kubernetes в Docker Desktop
2. Используйте Git Bash или WSL для запуска скриптов

## Проверка готовности

Перед запуском убедитесь что:
- Minikube запущен: `minikube start`
- kubectl настроен: `kubectl cluster-info`
- Git Bash или WSL доступны

## Альтернатива: Выполнение команд вручную

Если скрипты не запускаются, можно выполнить команды из скриптов вручную:

1. Скопируйте содержимое скрипта
2. Выполните команды по одной в терминале
3. Или используйте `bash -c "команды из скрипта"`
