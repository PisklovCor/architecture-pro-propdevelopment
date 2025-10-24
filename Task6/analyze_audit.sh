#!/bin/bash

# Скрипт для анализа Kubernetes audit.log и извлечения подозрительных событий

AUDIT_LOG="${1:-audit.log}"
OUTPUT_FILE="audit-extract.json"

# Проверка наличия файла
if [ ! -f "$AUDIT_LOG" ]; then
    echo "Ошибка: Файл $AUDIT_LOG не найден!"
    echo "Использование: ./analyze_audit.sh [путь_к_audit.log]"
    exit 1
fi

# Проверка наличия jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка: jq не установлен!"
    echo "Установите jq для работы скрипта:"
    echo "  На Windows (Git Bash): скачайте jq-win64.exe с https://stedolan.github.io/jq/download/"
    echo "  На Linux: sudo apt-get install jq"
    echo "  На macOS: brew install jq"
    exit 1
fi

echo "=== Анализ audit.log ==="
echo "Файл: $AUDIT_LOG"
echo ""

# Временные файлы
TMP_SECRET_ACCESS="/tmp/audit_secret_access_$$.json"
TMP_EXEC_CMD="/tmp/audit_exec_cmd_$$.json"
TMP_PRIVILEGED_POD="/tmp/audit_privileged_pod_$$.json"
TMP_DANGEROUS_BINDING="/tmp/audit_dangerous_binding_$$.json"
TMP_AUDIT_POLICY="/tmp/audit_audit_policy_$$.json"

# Очистка временных файлов при выходе
trap "rm -f $TMP_SECRET_ACCESS $TMP_EXEC_CMD $TMP_PRIVILEGED_POD $TMP_DANGEROUS_BINDING $TMP_AUDIT_POLICY" EXIT

# 1. Поиск доступа к secrets
echo "Поиск доступа к secrets..."
jq -c 'select(.objectRef.resource=="secrets" and (.verb=="get" or .verb=="list")) | {
    type: "secret_access",
    timestamp: .timestamp,
    user: .user.username,
    namespace: .objectRef.namespace,
    verb: .verb,
    resource: .objectRef.name,
    response_status: .responseStatus.code,
    raw: .
}' "$AUDIT_LOG" 2>/dev/null > "$TMP_SECRET_ACCESS"

SECRET_COUNT=$(wc -l < "$TMP_SECRET_ACCESS" | tr -d ' ')
echo "  Найдено событий: $SECRET_COUNT"

# 2. Поиск kubectl exec
echo "Поиск kubectl exec команд..."
jq -c 'select(.verb=="create" and .objectRef.subresource=="exec") | {
    type: "exec_command",
    timestamp: .timestamp,
    user: .user.username,
    namespace: .objectRef.namespace,
    pod: .objectRef.name,
    raw: .
}' "$AUDIT_LOG" 2>/dev/null > "$TMP_EXEC_CMD"

EXEC_COUNT=$(wc -l < "$TMP_EXEC_CMD" | tr -d ' ')
echo "  Найдено событий: $EXEC_COUNT"

# 3. Поиск привилегированных подов
echo "Поиск привилегированных подов..."
jq -c 'select(.objectRef.resource=="pods" and .verb=="create" and .requestObject.spec.containers[]?.securityContext.privileged==true) | {
    type: "privileged_pod",
    timestamp: .timestamp,
    user: .user.username,
    namespace: .objectRef.namespace,
    pod: .objectRef.name,
    container: .requestObject.spec.containers[0].name,
    raw: .
}' "$AUDIT_LOG" 2>/dev/null > "$TMP_PRIVILEGED_POD"

PRIV_COUNT=$(wc -l < "$TMP_PRIVILEGED_POD" | tr -d ' ')
echo "  Найдено событий: $PRIV_COUNT"

# 4. Поиск RoleBinding с cluster-admin
echo "Поиск опасных RoleBinding..."
jq -c 'select((.objectRef.resource=="rolebindings" or .objectRef.resource=="clusterrolebindings") and .verb=="create" and .requestObject.roleRef.name=="cluster-admin") | {
    type: "dangerous_rolebinding",
    timestamp: .timestamp,
    user: .user.username,
    namespace: .objectRef.namespace,
    binding_name: .objectRef.name,
    subjects: .requestObject.subjects,
    raw: .
}' "$AUDIT_LOG" 2>/dev/null > "$TMP_DANGEROUS_BINDING"

BINDING_COUNT=$(wc -l < "$TMP_DANGEROUS_BINDING" | tr -d ' ')
echo "  Найдено событий: $BINDING_COUNT"

# 5. Поиск манипуляций с audit-policy
echo "Поиск манипуляций с audit-policy..."
grep -i 'audit-policy' "$AUDIT_LOG" 2>/dev/null | jq -c '{
    type: "audit_policy_manipulation",
    timestamp: .timestamp,
    user: .user.username,
    verb: .verb,
    raw: .
}' 2>/dev/null > "$TMP_AUDIT_POLICY"

POLICY_COUNT=$(wc -l < "$TMP_AUDIT_POLICY" | tr -d ' ')
echo "  Найдено событий: $POLICY_COUNT"

# Объединение всех результатов в один JSON файл
echo ""
echo "Объединение результатов..."

# Создаем массив JSON
{
    echo "["

    # Добавляем события с запятыми между ними
    FIRST=true

    for file in "$TMP_SECRET_ACCESS" "$TMP_EXEC_CMD" "$TMP_PRIVILEGED_POD" "$TMP_DANGEROUS_BINDING" "$TMP_AUDIT_POLICY"; do
        if [ -s "$file" ]; then
            while IFS= read -r line; do
                if [ "$FIRST" = true ]; then
                    FIRST=false
                else
                    echo ","
                fi
                echo "$line"
            done < "$file"
        fi
    done

    echo ""
    echo "]"
} | jq '.' > "$OUTPUT_FILE" 2>/dev/null

# Проверка создания файла
if [ -f "$OUTPUT_FILE" ]; then
    TOTAL_COUNT=$((SECRET_COUNT + EXEC_COUNT + PRIV_COUNT + BINDING_COUNT + POLICY_COUNT))

    echo ""
    echo "=== Результаты анализа ==="
    echo "Всего найдено подозрительных событий: $TOTAL_COUNT"
    echo "Результаты сохранены в: $OUTPUT_FILE"
    echo ""
    echo "Статистика по типам событий:"
    echo "  - secret_access: $SECRET_COUNT"
    echo "  - exec_command: $EXEC_COUNT"
    echo "  - privileged_pod: $PRIV_COUNT"
    echo "  - dangerous_rolebinding: $BINDING_COUNT"
    echo "  - audit_policy_manipulation: $POLICY_COUNT"
    echo ""

    # Показываем примеры найденных событий (первые 3)
    echo "=== Примеры найденных событий ==="

    if [ $SECRET_COUNT -gt 0 ]; then
        echo ""
        echo "1. Доступ к secrets:"
        jq -r '.[] | select(.type=="secret_access") | "   Пользователь: \(.user) | Namespace: \(.namespace) | Secret: \(.resource) | Статус: \(.response_status)"' "$OUTPUT_FILE" | head -3
    fi

    if [ $EXEC_COUNT -gt 0 ]; then
        echo ""
        echo "2. Kubectl exec:"
        jq -r '.[] | select(.type=="exec_command") | "   Пользователь: \(.user) | Namespace: \(.namespace) | Pod: \(.pod)"' "$OUTPUT_FILE" | head -3
    fi

    if [ $PRIV_COUNT -gt 0 ]; then
        echo ""
        echo "3. Привилегированные поды:"
        jq -r '.[] | select(.type=="privileged_pod") | "   Пользователь: \(.user) | Namespace: \(.namespace) | Pod: \(.pod)"' "$OUTPUT_FILE" | head -3
    fi

    if [ $BINDING_COUNT -gt 0 ]; then
        echo ""
        echo "4. Опасные RoleBinding:"
        jq -r '.[] | select(.type=="dangerous_rolebinding") | "   Пользователь: \(.user) | Namespace: \(.namespace) | Binding: \(.binding_name)"' "$OUTPUT_FILE" | head -3
    fi

    if [ $POLICY_COUNT -gt 0 ]; then
        echo ""
        echo "5. Манипуляции с audit-policy:"
        jq -r '.[] | select(.type=="audit_policy_manipulation") | "   Пользователь: \(.user) | Действие: \(.verb)"' "$OUTPUT_FILE" | head -3
    fi

    echo ""
    echo "=== Для просмотра полного отчета ==="
    echo "cat $OUTPUT_FILE | jq '.'"

else
    echo "Ошибка: Не удалось создать файл $OUTPUT_FILE"
    exit 1
fi
