#!/bin/bash

# Default values
MODEL="${OPENAI_MODEL:-gpt-5}"
# MODEL="openai/gpt-oss-120b"
BASE_URL="${OPENAI_BASE_URL:-https://agentrouter.org/v1}"
# BASE_URL="${OPENAI_BASE_URL:-https://openrouter.ai/api/v1}"
MESSAGE="Объясни что такое нейронная сеть простыми словами"
API_TYPE="both"  # Options: chat, responses, both
MAX_TOKENS="${OPENAI_API_MAX_TOKENS:-1000}"
SAVE_LOG=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        --message)
            MESSAGE="$2"
            shift 2
            ;;
        --type)
            API_TYPE="$2"
            shift 2
            ;;
        --max-tokens)
            MAX_TOKENS="$2"
            shift 2
            ;;
        --save-log)
            SAVE_LOG=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--model MODEL] [--url BASE_URL] [--message MESSAGE] [--type API_TYPE] [--max-tokens N] [--save-log]"
            echo ""
            echo "Options:"
            echo "  --model      Model to use (default: gpt-5 or \$OPENAI_MODEL)"
            echo "  --url        Base URL for API (default: \$OPENAI_BASE_URL or https://agentrouter.org/v1)"
            echo "  --message    Test message to send (default: 'Объясни что такое нейронная сеть простыми словами')"
            echo "  --type       API type to test: chat, responses, both (default: both)"
            echo "  --max-tokens Maximum tokens to generate (default: 1000 or \$OPENAI_API_MAX_TOKENS)"
            echo "  --save-log   Save request and response to JSON log file (default: false)"
            echo ""
            echo "Environment variables:"
            echo "  OPENAI_API_KEY        API key for authentication (required)"
            echo "  OPENAI_BASE_URL       Base URL for API"
            echo "  OPENAI_MODEL          Model to use (default: gpt-5)"
            echo "  OPENAI_API_MAX_TOKENS Maximum tokens to generate (default: 1000)"
            echo ""
            echo "Supported APIs:"
            echo "  Chat Completions API (/chat/completions):"
            echo "    - Supported by all providers (OpenAI, OpenRouter, AgentRouter, etc.)"
            echo ""
            echo "  Responses API:"
            echo "    - OpenRouter: /responses endpoint (simple format)"
            echo "    - OpenAI: /sessions + /sessions/{id}/responses (complex format)"
            echo "    - Other providers: not supported"
            echo ""
            echo "Examples:"
            echo "  ./test-openai.sh --type chat"
            echo "  ./test-openai.sh --model gpt-4 --message 'Hello world'"
            echo "  export OPENAI_MODEL='openai/gpt-oss-20b:free' && ./test_openai.sh"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if API key is set
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    exit 1
fi

# Remove trailing slash from BASE_URL if present
BASE_URL=${BASE_URL%/}

# Clean variables from potential carriage return characters (Windows line endings)
MODEL=$(echo "$MODEL" | tr -d '\r' | tr -d '"' | xargs)
BASE_URL=$(echo "$BASE_URL" | tr -d '\r' | tr -d '"' | xargs)
MESSAGE=$(echo "$MESSAGE" | tr -d '\r' | xargs)
OPENAI_API_KEY=$(echo "$OPENAI_API_KEY" | tr -d '\r' | tr -d '"' | xargs)

echo "Testing OpenAI API:"
echo "  Model: $MODEL"
echo "  Base URL: $BASE_URL"
echo "  Message: $MESSAGE"
echo "  API Type: $API_TYPE"
echo "  Max Tokens: $MAX_TOKENS"
if [[ "$SAVE_LOG" == "true" ]]; then
    LOG_FILE="openai-test-$(date +%Y%m%d-%H%M%S).json"
    echo "  Log file: $LOG_FILE"
fi
echo ""

# Initialize log data storage
CHAT_REQUEST=""
CHAT_RESPONSE=""
RESPONSES_REQUEST=""
RESPONSES_RESPONSE=""

# Determine which Responses API format to use
# OpenRouter has its own /responses endpoint (simpler format)
# OpenAI uses /sessions and /sessions/{id}/responses (complex format)
# Other providers typically don't support Responses API at all

RESPONSES_API_TYPE="none"

if [[ "$BASE_URL" == *"openrouter.ai"* ]]; then
    RESPONSES_API_TYPE="openrouter"
elif [[ "$BASE_URL" == *"api.openai.com"* || "$BASE_URL" == *"openai.azure.com"* ]]; then
    RESPONSES_API_TYPE="openai"
fi

# Warn if Responses API is not supported
if [[ "$RESPONSES_API_TYPE" == "none" ]]; then
    if [[ "$API_TYPE" == "responses" || "$API_TYPE" == "both" ]]; then
        echo "⚠️  Warning: This API endpoint does not support Responses API"
        echo "   Only Chat Completions API will be tested."
        echo ""
        if [[ "$API_TYPE" == "responses" ]]; then
            API_TYPE="chat"
        elif [[ "$API_TYPE" == "both" ]]; then
            API_TYPE="chat"
        fi
    fi
fi

# Function to test Chat Completions API
test_chat_completions() {
    echo "═══════════════════════════════════════"
    echo "🔵 Testing Chat Completions API"
    echo "═══════════════════════════════════════"
    
    # Prepare request body
    request_body="{
        \"model\": \"$MODEL\",
        \"messages\": [
            {
                \"role\": \"user\",
                \"content\": \"$MESSAGE\"
            }
        ],
        \"max_tokens\": $MAX_TOKENS
    }"
    
    # Save request if logging enabled
    if [[ "$SAVE_LOG" == "true" ]]; then
        CHAT_REQUEST="$request_body"
    fi
    
    response=$(curl -s -S -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "HTTP-Referer: https://github.com/test" \
        -H "X-Title: OpenAI Test Script" \
        -d "$request_body" \
        "$BASE_URL/chat/completions" 2>&1)
    
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    # Save response if logging enabled
    if [[ "$SAVE_LOG" == "true" ]]; then
        CHAT_RESPONSE="$response_body"
    fi
    
    echo "HTTP Status: $http_status"
    
    # Check if we got a valid HTTP status
    if [[ -z "$http_status" || "$http_status" == "000" ]]; then
        echo ""
        echo "❌ Connection error:"
        echo "$response_body"
        echo ""
        echo "Possible causes:"
        echo "  - Network connectivity issues"
        echo "  - Invalid BASE_URL: $BASE_URL"
        echo "  - SSL/TLS certificate problems"
        echo "  - Server is unreachable"
        echo ""
        return 1
    fi
    
    echo ""
    
    if [[ $http_status -eq 200 ]]; then
        # Extract main content and reasoning first
        content=$(echo "$response_body" | jq -r '.choices[0].message.content' 2>/dev/null)
        reasoning=$(echo "$response_body" | jq -r '.choices[0].message.reasoning' 2>/dev/null)
        
        if [[ -n "$content" && "$content" != "null" ]]; then
            # Show reasoning first if present
            if [[ -n "$reasoning" && "$reasoning" != "null" ]]; then
                echo "💭 Reasoning tokens (model's thought process):"
                echo "$reasoning"
                echo ""
            fi
            
            # Then show main response
            echo "✅ Success! Model response:"
            echo "$content"
            
            # Show usage statistics
            echo ""
            echo "📊 Token Usage:"
            prompt_tokens=$(echo "$response_body" | jq -r '.usage.prompt_tokens // "N/A"' 2>/dev/null)
            completion_tokens=$(echo "$response_body" | jq -r '.usage.completion_tokens // "N/A"' 2>/dev/null)
            total_tokens=$(echo "$response_body" | jq -r '.usage.total_tokens // "N/A"' 2>/dev/null)
            
            echo "  Input tokens:  $prompt_tokens"
            echo "  Output tokens: $completion_tokens"
            echo "  Total tokens:  $total_tokens"
        else
            echo "✅ Success! Model response:"
            echo "Raw response (jq not available or unexpected format):"
            echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
        fi
    else
        echo "❌ Error occurred:"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    echo ""
}

# Function to test OpenRouter Responses API
test_openrouter_responses_api() {
    echo "═══════════════════════════════════════"
    echo "🟢 Testing OpenRouter Responses API"
    echo "═══════════════════════════════════════"
    
    # Prepare request body
    request_body="{
        \"model\": \"$MODEL\",
        \"input\": [
            {
                \"role\": \"user\",
                \"content\": \"$MESSAGE\"
            }
        ]
    }"
    
    # Save request if logging enabled
    if [[ "$SAVE_LOG" == "true" ]]; then
        RESPONSES_REQUEST="$request_body"
    fi
    
    response=$(curl -s -S -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "HTTP-Referer: https://github.com/test" \
        -H "X-Title: OpenAI Test Script" \
        -d "$request_body" \
        "$BASE_URL/responses" 2>&1)
    
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    # Save response if logging enabled
    if [[ "$SAVE_LOG" == "true" ]]; then
        RESPONSES_RESPONSE="$response_body"
    fi
    
    echo "HTTP Status: $http_status"
    
    # Check if we got a valid HTTP status
    if [[ -z "$http_status" || "$http_status" == "000" ]]; then
        echo ""
        echo "❌ Connection error:"
        echo "$response_body"
        echo ""
        echo "Possible causes:"
        echo "  - Network connectivity issues"
        echo "  - Invalid BASE_URL: $BASE_URL"
        echo "  - SSL/TLS certificate problems"
        echo "  - Server is unreachable"
        echo ""
        return 1
    fi
    
    echo ""
    
    if [[ $http_status -eq 200 ]]; then
        # OpenRouter returns multiple output elements:
        # 1. type: "reasoning" - model's thinking process (reasoning tokens)
        # 2. type: "message" with role: "assistant" - final response
        
        # Extract both reasoning and assistant message
        reasoning=$(echo "$response_body" | jq -r '.output[] | select(.type == "reasoning") | .content[0].text' 2>/dev/null)
        assistant_message=$(echo "$response_body" | jq -r '.output[] | select(.role == "assistant") | .content[0].text' 2>/dev/null)
        
        if [[ -n "$assistant_message" && "$assistant_message" != "null" ]]; then
            # Show reasoning first if present
            if [[ -n "$reasoning" && "$reasoning" != "null" ]]; then
                echo "💭 Reasoning tokens (model's thought process):"
                echo "$reasoning"
                echo ""
            fi
            
            # Then show main response
            echo "✅ Success! Model response:"
            echo "$assistant_message"
            
            # Show usage statistics (Responses API has more detailed info including cost)
            echo ""
            echo "📊 Token Usage:"
            input_tokens=$(echo "$response_body" | jq -r '.usage.input_tokens // "N/A"' 2>/dev/null)
            output_tokens=$(echo "$response_body" | jq -r '.usage.output_tokens // "N/A"' 2>/dev/null)
            reasoning_tokens=$(echo "$response_body" | jq -r '.usage.output_tokens_details.reasoning_tokens // "0"' 2>/dev/null)
            cached_tokens=$(echo "$response_body" | jq -r '.usage.input_tokens_details.cached_tokens // "0"' 2>/dev/null)
            total_tokens=$(echo "$response_body" | jq -r '.usage.total_tokens // "N/A"' 2>/dev/null)
            cost=$(echo "$response_body" | jq -r '.usage.cost // "N/A"' 2>/dev/null)
            
            echo "  Input tokens:     $input_tokens (cached: $cached_tokens)"
            echo "  Output tokens:    $output_tokens (reasoning: $reasoning_tokens)"
            echo "  Total tokens:     $total_tokens"
            if [[ "$cost" != "N/A" && "$cost" != "null" ]]; then
                echo "  💰 Cost:          \$${cost}"
            fi
        else
            # Fallback: try to get any text from output
            fallback_text=$(echo "$response_body" | jq -r '.output[0].content[0].text' 2>/dev/null)
            if [[ -n "$fallback_text" && "$fallback_text" != "null" ]]; then
                echo "✅ Success! Model response:"
                echo "$fallback_text"
            else
                echo "✅ Success! Model response:"
                echo "Raw response (unexpected format):"
                echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
            fi
        fi
    else
        echo "❌ Error occurred:"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    echo ""
}

# Function to test OpenAI Responses API (with sessions)
test_openai_responses_api() {
    echo "═══════════════════════════════════════"
    echo "🟢 Testing OpenAI Responses API (Sessions)"
    echo "═══════════════════════════════════════"
    
    # Step 1: Create a session
    echo "Step 1: Creating session..."
    session_response=$(curl -s -S -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "HTTP-Referer: https://github.com/test" \
        -H "X-Title: OpenAI Test Script" \
        -d "{
            \"model\": \"$MODEL\",
            \"voice\": \"alloy\"
        }" \
        "$BASE_URL/sessions" 2>&1)
    
    session_http_status=$(echo "$session_response" | grep "HTTP_STATUS:" | cut -d: -f2)
    session_body=$(echo "$session_response" | sed '/HTTP_STATUS:/d')
    
    # Check if we got a valid HTTP status
    if [[ -z "$session_http_status" || "$session_http_status" == "000" ]]; then
        echo "❌ Connection error:"
        echo "$session_body"
        echo ""
        echo "Possible causes:"
        echo "  - Network connectivity issues"
        echo "  - Invalid BASE_URL: $BASE_URL"
        echo "  - SSL/TLS certificate problems"
        echo "  - Server is unreachable"
        echo ""
        return 1
    fi
    
    if [[ $session_http_status -ne 200 ]]; then
        echo "❌ Failed to create session (HTTP $session_http_status):"
        echo "$session_body" | jq . 2>/dev/null || echo "$session_body"
        echo ""
        return 1
    fi
    
    SESSION_ID=$(echo "$session_body" | jq -r '.id' 2>/dev/null)
    if [[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]]; then
        echo "❌ Failed to extract session ID from response:"
        echo "$session_body"
        echo ""
        return 1
    fi
    
    echo "✅ Session created: $SESSION_ID"
    echo ""
    
    # Step 2: Create a response
    echo "Step 2: Creating response..."
    response=$(curl -s -S -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "HTTP-Referer: https://github.com/test" \
        -H "X-Title: OpenAI Test Script" \
        -d "{
            \"modalities\": [\"text\"],
            \"instructions\": \"You are a helpful assistant.\",
            \"input\": [
                {
                    \"type\": \"message\",
                    \"role\": \"user\",
                    \"content\": [
                        {
                            \"type\": \"input_text\",
                            \"text\": \"$MESSAGE\"
                        }
                    ]
                }
            ]
        }" \
        "$BASE_URL/sessions/$SESSION_ID/responses" 2>&1)
    
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    echo "HTTP Status: $http_status"
    
    # Check if we got a valid HTTP status
    if [[ -z "$http_status" || "$http_status" == "000" ]]; then
        echo ""
        echo "❌ Connection error:"
        echo "$response_body"
        echo ""
        echo "Possible causes:"
        echo "  - Network connectivity issues"
        echo "  - Invalid BASE_URL: $BASE_URL"
        echo "  - SSL/TLS certificate problems"
        echo "  - Server is unreachable"
        echo ""
        return 1
    fi
    
    echo ""
    
    if [[ $http_status -eq 200 ]]; then
        echo "✅ Success! Response created:"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    else
        echo "❌ Error occurred:"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    echo ""
}

# Wrapper function to call the appropriate Responses API implementation
test_responses_api() {
    case $RESPONSES_API_TYPE in
        openrouter)
            test_openrouter_responses_api
            ;;
        openai)
            test_openai_responses_api
            ;;
        none)
            echo "═══════════════════════════════════════"
            echo "🟢 Testing Responses API"
            echo "═══════════════════════════════════════"
            echo "❌ Responses API is not supported for this endpoint"
            echo ""
            ;;
        *)
            echo "❌ Unknown Responses API type: $RESPONSES_API_TYPE"
            echo ""
            ;;
    esac
}

# Execute tests based on API_TYPE
case $API_TYPE in
    chat)
        test_chat_completions
        ;;
    responses)
        test_responses_api
        ;;
    both)
        test_chat_completions
        echo ""
        test_responses_api
        ;;
    *)
        echo "❌ Invalid API type: $API_TYPE"
        echo "Valid options: chat, responses, both"
        exit 1
        ;;
esac

# Save log if enabled
if [[ "$SAVE_LOG" == "true" ]]; then
    echo "═══════════════════════════════════════"
    echo "💾 Saving log to $LOG_FILE"
    echo "═══════════════════════════════════════"
    
    # Build JSON structure
    log_json="{"
    
    # Add chat_completions_api if it was executed
    if [[ -n "$CHAT_REQUEST" ]]; then
        log_json="$log_json
  \"chat_completions_api\": {
    \"request\": $CHAT_REQUEST,
    \"response\": $CHAT_RESPONSE
  }"
    fi
    
    # Add comma if both APIs were executed
    if [[ -n "$CHAT_REQUEST" && -n "$RESPONSES_REQUEST" ]]; then
        log_json="$log_json,"
    fi
    
    # Add responses_api if it was executed
    if [[ -n "$RESPONSES_REQUEST" ]]; then
        log_json="$log_json
  \"responses_api\": {
    \"request\": $RESPONSES_REQUEST,
    \"response\": $RESPONSES_RESPONSE
  }"
    fi
    
    log_json="$log_json
}"
    
    # Save to file with pretty formatting
    echo "$log_json" | jq . > "$LOG_FILE" 2>/dev/null || echo "$log_json" > "$LOG_FILE"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Log saved successfully to: $LOG_FILE"
    else
        echo "❌ Failed to save log file"
    fi
    echo ""
fi