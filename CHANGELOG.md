# Changelog

## 2024-10-18 - Добавлена поддержка кастомных HTTP заголовков

### Новые возможности

#### 1. Параметр `--add-headers`

Позволяет добавлять кастомные HTTP заголовки через командную строку:

```bash
./test_openai.sh --add-headers "X-Custom: value1; X-Test: value2"
```

- Заголовки разделяются точкой с запятой (`;`)
- Поддерживаются любые корректные HTTP заголовки
- Заголовки автоматически добавляются во все API запросы

#### 2. Параметр `--add-headers-file`

Позволяет загружать заголовки из файла:

```bash
./test_openai.sh --add-headers-file headers.txt
```

- Один заголовок на строку
- Строки, начинающиеся с `#`, игнорируются (комментарии)
- Пустые строки игнорируются

Пример файла `headers.txt`:

```text
# Комментарий
User-Agent: MyApp/1.0
X-Custom-Header: test-value
X-Request-ID: 12345
```

#### 3. Отображение кастомных заголовков в консоли

При использовании кастомных заголовков они отображаются в начале вывода:

```
Testing OpenAI API:
  Model: gpt-5
  Base URL: https://agentrouter.org/v1
  Message: Объясни что такое нейронная сеть простыми словами
  API Type: both
  Max Tokens: 1000
  Custom Headers:
    X-Custom-Header: value1
    X-Request-ID: 12345
```

#### 4. Сохранение заголовков в логах

При использовании флага `--save-log` создаётся JSON файл с расширенными метаданными:

```json
{
  "metadata": {
    "timestamp": "2024-10-18T22:10:29Z",
    "model": "gpt-5",
    "base_url": "https://agentrouter.org/v1",
    "max_tokens": 1000,
    "message": "...",
    "custom_headers": [
      "X-Custom-Header: value1",
      "X-Request-ID: 12345"
    ]
  },
  "chat_completions_api": { ... },
  "responses_api": { ... }
}
```

### Технические изменения

1. **Рефакторинг curl команд**

   - Переход с inline eval на построение команды через переменную
   - Улучшенная обработка специальных символов в заголовках
   - Применение кастомных заголовков ко всем типам API:
     - Chat Completions API
     - OpenRouter Responses API
     - OpenAI Responses API (оба запроса: session и response)

2. **Улучшенная структура логов**

   - Добавлен раздел `metadata` с полной информацией о запросе
   - Сохранение timestamp в ISO 8601 формате
   - Кастомные заголовки сохраняются как массив строк

3. **Обновлённая документация**
   - Добавлены примеры использования кастомных заголовков
   - Обновлена таблица параметров командной строки
   - Добавлена инструкция по тестированию (TESTING_CUSTOM_HEADERS.md)
   - Обновлён формат лог-файлов в README

### Примеры использования

```bash
# Через командную строку
./test_openai.sh --add-headers "X-Test: 1; User-Agent: MyBot/1.0"

# Через файл
./test_openai.sh --add-headers-file headers.txt

# С логированием
./test_openai.sh --add-headers "X-Custom: value" --save-log

# Комбинация параметров
./test_openai.sh \
  --model gpt-4 \
  --add-headers "X-Request-ID: abc123" \
  --type both \
  --save-log
```

### Совместимость

- ✅ Работает со всеми поддерживаемыми провайдерами (OpenAI, OpenRouter, AgentRouter)
- ✅ Обратная совместимость: все существующие команды работают без изменений
- ✅ Кастомные заголовки опциональны и не требуются для работы скрипта

### Файлы

- `test_openai.sh` - обновлён основной скрипт
- `headers.txt` - пример файла с заголовками
- `README.md` - обновлена документация
- `TESTING_CUSTOM_HEADERS.md` - инструкция по тестированию
- `CHANGELOG.md` - этот файл
