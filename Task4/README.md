verify_rbac.sh
## Порядок выполнения

1. **Запустите Minikube:**
   ```bash
   minikube start
   ```

2. **Создайте пользователей:**
   ```bash
   ./create_users.sh
   ```

3. **Создайте роли:**
   ```bash
   ./create_roles.sh
   ```

4. **Свяжите пользователей с ролями:**
   ```bash
   ./bind_users_roles.sh
   ```

5. **Проверьте настройки:**
   ```bash
   # Быстрая проверка
   ./quick_test.sh
   
   # Полная проверка
   ./verify_rbac.sh
   ```

## Созданные роли

### Cluster Roles
- **cluster-admin-custom** - Полный доступ ко всем ресурсам кластера
- **cluster-operator** - Операционное управление приложениями
- **cluster-viewer** - Только просмотр ресурсов (кроме секретов)
- **namespace-admin** - Полный доступ к ресурсам в namespace
- **namespace-developer** - Создание и изменение приложений в namespace

### Пользователи и группы

| Группа | Пользователи | Роль | Доступ |
|--------|-------------|------|--------|
| cluster-admins | admin1, admin2 | cluster-admin-custom | Полный доступ к кластеру |
| devops-operators | devops1-3 | cluster-operator + namespace-admin (production) | Операционное управление + админ production |
| team-leads | lead1, lead2 | namespace-admin | Администратор всех namespace |
| developers | dev1-5 | namespace-developer | Разработка в development/testing |
| analysts | analyst1, analyst2 | cluster-viewer | Только просмотр |

## Namespace

Созданы следующие namespace:
- `development` - для разработки
- `production` - для продакшена  
- `testing` - для тестирования

## Проверка прав

### Автоматическая проверка

Используйте готовые скрипты для проверки:

```bash
# Быстрая проверка основных прав
./quick_test.sh

# Полная детальная проверка
./verify_rbac.sh
```

### Ручная проверка

Для проверки прав пользователя используйте:
```bash
kubectl auth can-i <verb> <resource> --as=<username>
```

Примеры:
```bash
# Проверить может ли dev1 создавать pods в development
kubectl auth can-i create pods --as=dev1 -n development

# Проверить может ли analyst1 просматривать секреты
kubectl auth can-i get secrets --as=analyst1

# Проверить может ли admin1 удалять любые ресурсы
kubectl auth can-i delete pods --as=admin1
```

## Переключение между пользователями

```bash
# Переключиться на пользователя
kubectl config use-context <username>-context

# Вернуться к admin контексту
kubectl config use-context minikube
```

## Безопасность

- Все пользователи аутентифицируются через сертификаты
- Сертификаты подписаны CA кластера Minikube
- Права строго разграничены по принципу минимальных привилегий
- Секреты доступны только администраторам и лидам команд

