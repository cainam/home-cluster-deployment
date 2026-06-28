
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


podman run --rm -w /claude -e HOME=/claude -e CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1 -e ANTHROPIC_AUTH_TOKEN="$K" -e ANTHROPIC_BASE_URL=https://openrouter.ai/api -v /tmp/claude:/claude -v /etc/passwd:/etc/passwd --user podman myregistry.adm13:443/local/claude:20260521  /opt/bin/claude --verbose -p --output-format stream-json --dangerously-skip-permissions "Write a one-line Python function that returns the factorial of a number" | jq -r 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text'
