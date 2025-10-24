### 1. Namespace с политикой безопасности
- **Файл**: `01-create-namespace.yaml`
- **Назначение**: Создает namespace `audit-zone` с уровнем PodSecurity `restricted`
- **Особенности**: Применяет строгие политики безопасности на уровне namespace

### 2. Небезопасные манифесты (insecure-manifests/)
- **01-privileged-pod.yaml**: Pod с `privileged: true` - нарушение безопасности
- **02-hostpath-pod.yaml**: Pod с монтированием hostPath - потенциальная утечка данных
- **03-root-user-pod.yaml**: Pod с запуском от root (UID 0) - нарушение принципа минимальных привилегий

### 3. Безопасные манифесты (secure-manifests/)
- **01-secure.yaml, 02-secure.yaml, 03-secure.yaml**: Исправленные версии с:
  - `runAsNonRoot: true`
  - `readOnlyRootFilesystem: true`
  - `allowPrivilegeEscalation: false`
  - `capabilities.drop: ["ALL"]`
  - Использование `emptyDir` вместо `hostPath`

### 4. OPA Gatekeeper конфигурация

#### Constraint Templates (gatekeeper/constraint-templates/)
- **privileged.yaml**: Запрещает privileged контейнеры
- **hostpath.yaml**: Запрещает hostPath volumes
- **runasnonroot.yaml**: Требует runAsNonRoot и readOnlyRootFilesystem

#### Constraints (gatekeeper/constraints/)
- **privileged.yaml**: Применяет запрет на privileged контейнеры в audit-zone
- **hostpath.yaml**: Применяет запрет на hostPath в audit-zone
- **runasnonroot.yaml**: Применяет требования безопасности в audit-zone

### 5. Скрипты проверки (verify/)
- **verify-admission.sh**: Тестирует работу PodSecurity Admission Controller
- **validate-security.sh**: Проверяет статус Gatekeeper и политик

### 6. Политика аудита
- **audit-policy.yaml**: Настраивает детальное логирование событий в audit-zone

## Ключевые принципы безопасности

1. **Принцип минимальных привилегий**: Контейнеры запускаются от непривилегированных пользователей
2. **Неизменяемость**: readOnlyRootFilesystem предотвращает модификацию файловой системы
3. **Изоляция**: Запрет hostPath предотвращает доступ к хостовой файловой системе
4. **Контроль привилегий**: Запрет privileged контейнеров и escalation привилегий

## Проверка работы

1. **Установка Gatekeeper**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
   ```

2. **Применение constraint templates**:
   ```bash
   kubectl apply -f gatekeeper/constraint-templates/
   ```

3. **Применение constraints**:
   ```bash
   kubectl apply -f gatekeeper/constraints/
   ```

4. **Тестирование**:
   ```bash
   chmod +x verify/*.sh
   ./verify/verify-admission.sh
   ./verify/validate-security.sh
   ```

## Ожидаемые результаты

- Небезопасные манифесты должны быть отклонены admission controller
- Безопасные манифесты должны успешно создаваться
- Gatekeeper должен блокировать нарушения политик
- Аудит должен логировать все события безопасности

## Мониторинг и аудит

Система обеспечивает:
- Автоматическое отклонение небезопасных конфигураций
- Детальное логирование событий безопасности
- Централизованное управление политиками через Gatekeeper
- Соответствие стандартам безопасности Kubernetes
