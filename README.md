# OpenAI API Test Scripts

Набор Bash-скриптов для тестирования OpenAI-совместимых API, включая OpenRouter, с поддержкой различных форматов API (Chat Completions и Responses API).

## 🚀 Возможности

- ✅ Тестирование **Chat Completions API** (стандартный формат OpenAI)
- ✅ Тестирование **Responses API** (OpenAI session-based и OpenRouter direct)
- ✅ Автоматическое определение типа API по BASE_URL
- ✅ Поддержка reasoning tokens (токены размышления модели)
- ✅ Отображение детальной статистики использования токенов
- ✅ Расчёт стоимости запросов (если API возвращает cost)
- ✅ Сохранение логов запросов и ответов в JSON
- ✅ Гибкая настройка через переменные окружения и аргументы командной строки
- ✅ Поддержка кастомных HTTP заголовков (через параметр или файл)

## 📋 Требования

- **Bash** 4.0+
- **curl** - для HTTP-запросов
- **jq** - для парсинга JSON

### Установка зависимостей

**Ubuntu/Debian:**

```bash
sudo apt-get install curl jq
```

**macOS:**

```bash
brew install curl jq
```

**Windows (WSL):**

```bash
sudo apt-get install curl jq
```

## 🔧 Настройка

### 1. Создайте файл с переменными окружения

Скопируйте `example.env` и создайте свой файл конфигурации:

```bash
cp example.env openrouter.env
# Затем отредактируйте openrouter.env и укажите ваш API ключ
```

Или создайте файл `.env` вручную (например, `openrouter.env` или `agentrouter.env`) со следующим содержимым:

**Для OpenRouter:**

```bash
export OPENAI_API_KEY="sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="openai/gpt-4o-2024-11-20"
export OPENAI_API_MAX_TOKENS=1000
```

**Для OpenAI:**

```bash
export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_MODEL="gpt-4"
export OPENAI_API_MAX_TOKENS=1000
```

**Для других провайдеров:**

```bash
export OPENAI_API_KEY="your-api-key"
export OPENAI_BASE_URL="https://your-provider.com/v1"
export OPENAI_MODEL="gpt-5"
export OPENAI_API_MAX_TOKENS=1000
```

### 2. Сделайте скрипты исполняемыми

```bash
chmod +x test_openai.sh
chmod +x test_openrouter_responses.sh
```

## 📖 Использование

### test_openai.sh - Универсальный тестировщик API

Основной скрипт с поддержкой различных типов API.

#### Базовое использование

```bash
# Загрузить переменные окружения и запустить
source openrouter.env
./test_openai.sh
```

#### Примеры с параметрами

**Указать кастомное сообщение:**

```bash
./test_openai.sh "Объясни квантовую физику простыми словами"
```

**Переопределить модель:**

```bash
./test_openai.sh --model "anthropic/claude-3.5-sonnet" "Привет!"
```

**Указать максимум токенов:**

```bash
./test_openai.sh --max-tokens 2000 "Напиши подробную статью о нейросетях"
```

**Тестировать только Chat Completions API:**

```bash
./test_openai.sh --type chat "Что такое ИИ?"
```

**Тестировать только Responses API:**

```bash
./test_openai.sh --type responses "Расскажи про машинное обучение"
```

**Сохранить лог запросов и ответов:**

```bash
./test_openai.sh --save-log "Тестовое сообщение"
```

**Добавить кастомные HTTP заголовки:**

```bash
# Через параметр командной строки (разделитель - точка с запятой)
./test_openai.sh --add-headers "X-Custom-Header: value1; X-Request-ID: 12345" "Тест"

# Через файл
./test_openai.sh --add-headers-file headers.txt "Тест с заголовками из файла"
```

**Пример файла headers.txt:**

```text
# Комментарии начинаются с #
User-Agent: MyApp/1.0
X-Custom-Header: test-value
X-Request-ID: 12345
```

**Комбинация параметров:**

```bash
./test_openai.sh \
  --model "openai/gpt-4o-2024-11-20" \
  --max-tokens 1500 \
  --type both \
  --save-log \
  "Объясни принцип работы трансформеров в NLP"
```

#### Параметры командной строки

| Параметр             | Описание                                               | Значение по умолчанию                 |
| -------------------- | ------------------------------------------------------ | ------------------------------------- |
| `--model MODEL`      | Модель для использования                               | `$OPENAI_MODEL` или `gpt-5`           |
| `--url BASE_URL`     | Базовый URL API                                        | `$OPENAI_BASE_URL`                    |
| `--message MESSAGE`  | Тестовое сообщение                                     | "Объясни что такое нейронная сеть..." |
| `--type TYPE`        | Тип API для тестирования (`chat`, `responses`, `both`) | `both`                                |
| `--max-tokens N`     | Максимальное количество токенов                        | `$OPENAI_API_MAX_TOKENS` или `1000`   |
| `--save-log`         | Сохранить лог в JSON файл                              | `false`                               |
| `--add-headers HDRS` | Добавить кастомные HTTP заголовки (разделитель `;`)    | -                                     |
| `--add-headers-file` | Загрузить заголовки из файла (по одному на строку)     | -                                     |
| `--help`             | Показать справку                                       | -                                     |

#### Переменные окружения

| Переменная              | Описание                        | Обязательная               |
| ----------------------- | ------------------------------- | -------------------------- |
| `OPENAI_API_KEY`        | API ключ для аутентификации     | ✅ Да                      |
| `OPENAI_BASE_URL`       | Базовый URL API                 | Нет (по умолчанию OpenAI)  |
| `OPENAI_MODEL`          | Модель для использования        | Нет (по умолчанию `gpt-5`) |
| `OPENAI_API_MAX_TOKENS` | Максимальное количество токенов | Нет (по умолчанию `1000`)  |

### test_openrouter_responses.sh - Специализированный тестировщик OpenRouter

Упрощённый скрипт специально для OpenRouter Responses API.

#### Использование

```bash
# Установить переменные
export OPENAI_API_KEY="sk-or-v1-xxxxx"
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="openai/gpt-4o-2024-11-20"

# Запустить
./test_openrouter_responses.sh "Привет, как дела?"
```

## 📊 Примеры вывода

### Chat Completions API

```
═══════════════════════════════════════
🔵 Testing Chat Completions API
═══════════════════════════════════════
HTTP Status: 200

💭 Reasoning tokens (model's thought process):
Пользователь просит объяснить нейросети простыми словами...

✅ Success! Model response:
Нейронная сеть — это программа, которая учится решать задачи по примерам...

📊 Token Usage:
  Input tokens:     18 (cached: 0)
  Output tokens:    617 (reasoning: 250)
  Total tokens:     635
  💰 Cost:          $0.0052
```

### OpenRouter Responses API

```
═══════════════════════════════════════
🟢 Testing OpenRouter Responses API
═══════════════════════════════════════
HTTP Status: 200

✅ Success! Model response:
Нейронная сеть — это способ научить компьютер...

📊 Token Usage:
  Input tokens:     18 (cached: 0)
  Output tokens:    1040 (reasoning: 704)
  Total tokens:     1058
  💰 Cost:          $0.0104225
```

## 💾 Формат лог-файлов

При использовании параметра `--save-log`, создаётся файл с именем `openai-test-YYYYMMDD-HHMMSS.json`:

```json
{
  "metadata": {
    "timestamp": "2024-10-18T22:10:29Z",
    "model": "openai/gpt-4o-2024-11-20",
    "base_url": "https://openrouter.ai/api/v1",
    "max_tokens": 1000,
    "message": "Объясни что такое нейронная сеть",
    "custom_headers": [
      "X-Custom-Header: test-value",
      "X-Request-ID: 12345"
    ]
  },
  "chat_completions_api": {
    "request": {
      "model": "openai/gpt-4o-2024-11-20",
      "messages": [
        {
          "role": "user",
          "content": "Объясни что такое нейронная сеть"
        }
      ],
      "max_tokens": 1000
    },
    "response": {
      "id": "gen-xxxxx",
      "model": "openai/gpt-4o-2024-11-20",
      "choices": [
        {
          "message": {
            "role": "assistant",
            "content": "Нейронная сеть — это..."
          }
        }
      ],
      "usage": {
        "prompt_tokens": 18,
        "completion_tokens": 617,
        "total_tokens": 635
      }
    }
  },
  "responses_api": {
    "request": {
      "model": "openai/gpt-4o-2024-11-20",
      "input": [
        {
          "role": "user",
          "content": "Объясни что такое нейронная сеть"
        }
      ]
    },
    "response": {
      "id": "gen-xxxxx",
      "output": [...],
      "usage": {
        "input_tokens": 18,
        "output_tokens": 1040,
        "total_tokens": 1058,
        "cost": 0.0104225
      }
    }
  }
}
```

## 🔍 Особенности разных API

### Chat Completions API

- ✅ Поддерживается всеми провайдерами
- ✅ Стандартный формат OpenAI
- ✅ Поле `messages` в запросе
- ✅ Поле `choices[0].message.content` в ответе

### OpenAI Responses API (Session-based)

- ⚠️ Требует создания сессии (`/sessions`)
- ⚠️ Затем генерация ответа (`/sessions/{id}/responses`)
- ⚠️ Двухшаговый процесс

### OpenRouter Responses API (Direct)

- ✅ Одношаговый процесс (`/responses`)
- ✅ Поле `input` вместо `messages` в запросе
- ✅ Поле `output` в ответе
- ✅ Поддержка reasoning tokens (внутренние размышления модели)
- ✅ Возвращает детальную статистику и стоимость

## 🐛 Устранение проблем

### Ошибка: `curl: (3) URL rejected: Malformed input to a URL function`

**Причина:** Windows line endings (`\r`) в `.env` файле.

**Решение:** Преобразуйте файл в Unix формат:

```bash
dos2unix your-file.env
# или
sed -i 's/\r$//' your-file.env
```

### Ошибка: `HTTP Status: 000`

**Возможные причины:**

- Неверный `BASE_URL`
- Проблемы с сетевым подключением
- SSL/TLS сертификаты
- Сервер недоступен

**Решение:** Проверьте BASE_URL и подключение к интернету.

### Ошибка: `HTTP Status: 401`

**Причина:** Неверный или отсутствующий API ключ.

**Решение:** Проверьте `OPENAI_API_KEY` в вашем `.env` файле.

### Пустой ответ при HTTP 200

**Причина:** Слишком маленькое значение `max_tokens` (reasoning tokens занимают большую часть лимита).

**Решение:** Увеличьте `max_tokens`:

```bash
./test_openai.sh --max-tokens 2000 "Ваше сообщение"
```

## 📝 Примеры для различных провайдеров

### OpenRouter (рекомендуется для тестирования)

```bash
# openrouter.env
export OPENAI_API_KEY="sk-or-v1-xxxxx"
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="openai/gpt-4o-2024-11-20"

source openrouter.env
./test_openai.sh --save-log "Тестовое сообщение"
```

### OpenAI

```bash
# openai.env
export OPENAI_API_KEY="sk-xxxxx"
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_MODEL="gpt-4"

source openai.env
./test_openai.sh "Hello, GPT-4!"
```

### Кастомный провайдер

```bash
# custom.env
export OPENAI_API_KEY="your-key"
export OPENAI_BASE_URL="https://custom-provider.com/v1"
export OPENAI_MODEL="custom-model"

source custom.env
./test_openai.sh --type chat "Test message"
```

### Использование с кастомными заголовками

```bash
# Через параметр командной строки
./test_openai.sh \
  --add-headers "User-Agent: MyBot/1.0; X-Request-ID: abc123" \
  --save-log \
  "Тестовое сообщение"

# Через файл заголовков
./test_openai.sh \
  --add-headers-file headers.txt \
  --type both \
  --save-log \
  "Сообщение с заголовками из файла"
```

## 🤝 Вклад в проект

Если вы нашли баг или хотите предложить улучшение, создайте Issue или Pull Request.

## 📄 Лицензия

Этот проект распространяется под лицензией MIT.

## 🔗 Полезные ссылки

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [OpenRouter API Documentation](https://openrouter.ai/docs)
- [OpenRouter Models](https://openrouter.ai/models)
