#!/usr/bin/env bash
set -euo pipefail

# === Настройки ===
API_KEY="${OPENROUTER_API_KEY:-}"   # Ключ нужно экспортировать перед запуском
MODEL="openai/gpt-oss-20b:free"
ENDPOINT="https://openrouter.ai/api/v1/responses"

if [[ -z "$API_KEY" ]]; then
  echo "❌ Ошибка: переменная окружения OPENROUTER_API_KEY не установлена."
  echo "👉 Выполните: export OPENROUTER_API_KEY='ваш_ключ'"
  exit 1
fi

# === Текст запроса ===
PROMPT=${1:-"Привет! Объясни, как работает градиентный спуск."}

# === Выполнение запроса ===
echo "🔹 Отправка запроса к $MODEL ..."
response=$(curl -sS -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $API_KEY" \
  -H "HTTP-Referer: https://example.com" \
  -H "X-Title: Bash Response Test" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"input\": [
      {\"role\": \"user\", \"content\": \"$PROMPT\"}
    ]
  }")

# === Обработка ответа ===
# Extract both reasoning and assistant message
reasoning=$(echo "$response" | jq -r '.output[] | select(.type == "reasoning") | .content[0].text' 2>/dev/null)
assistant_msg=$(echo "$response" | jq -r '.output[] | select(.role == "assistant") | .content[0].text' 2>/dev/null)

if [[ -n "$assistant_msg" && "$assistant_msg" != "null" ]]; then
  # Show reasoning first if present
  if [[ -n "$reasoning" && "$reasoning" != "null" ]]; then
    echo "💭 Reasoning tokens:"
    echo "$reasoning"
    echo ""
  fi
  
  # Then show main response
  echo "🔹 Ответ модели:"
  echo "$assistant_msg"
  
  # Show usage statistics
  echo ""
  echo "📊 Token Usage:"
  input_tokens=$(echo "$response" | jq -r '.usage.input_tokens // "N/A"')
  output_tokens=$(echo "$response" | jq -r '.usage.output_tokens // "N/A"')
  reasoning_tokens=$(echo "$response" | jq -r '.usage.output_tokens_details.reasoning_tokens // "0"')
  cached_tokens=$(echo "$response" | jq -r '.usage.input_tokens_details.cached_tokens // "0"')
  total_tokens=$(echo "$response" | jq -r '.usage.total_tokens // "N/A"')
  cost=$(echo "$response" | jq -r '.usage.cost // "N/A"')
  
  echo "  Input tokens:     $input_tokens (cached: $cached_tokens)"
  echo "  Output tokens:    $output_tokens (reasoning: $reasoning_tokens)"
  echo "  Total tokens:     $total_tokens"
  if [[ "$cost" != "N/A" && "$cost" != "null" ]]; then
    echo "  💰 Cost:          \$${cost}"
  fi
else
  # Fallback or error
  echo "🔹 Ответ модели:"
  echo "$response" | jq -r '.error // "Unexpected response format"'
fi
