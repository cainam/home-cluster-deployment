
openrouter.ai in the commandline, ANTHROPIC_BASE_URL=https://openrouter.ai/api
                  payload=$(jq -n --arg system_content "$(echo "$instructions"; cat "$flow")" '{"model": "poolside/laguna-xs.2:free",
                    "messages": [{"role": "system", "content": $system_content}]
                  }')
                  curl ${ANTHROPIC_BASE_URL}/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer ${ANTHROPIC_AUTH_TOKEN}" \
                    -H "HTTP-Referer: http://localhost:3000" \
                    -H "X-Title: My Batch Script" \
                    -d "$payload" | jq .  > "${ENRICHED_FLOWS}/${base_flow%.json}.ai-1.json"
