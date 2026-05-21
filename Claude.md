Claude with openrouter:

HOST_DIR=/tmp
CLAUDE_DIR=/claude
rm -rf $HOST_DIR/$CLAUDE_DIR
mkdir -p $HOST_DIR/$CLAUDE_DIR/.claude
echo -e '{"theme": "auto",
"model": "poolside/laguna-xs.2:free",
"smallModel": "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free"
}' > $HOST_DIR/$CLAUDE_DIR/.claude/settings.json

cat > $HOST_DIR/$CLAUDE_DIR/.claude.json << EOF
{
  "hasCompletedOnboarding": true,
  "projects": {
    "$CLAUDE_DIR": {
      "allowedTools": [],
      "hasTrustDialogAccepted": true
    }
  }
}
EOF
chown -R -h podman $HOST_DIR/$CLAUDE_DIR

podman run --rm -w /claude -e HOME=/claude -e CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1 -e ANTHROPIC_AUTH_TOKEN="$K" -e ANTHROPIC_BASE_URL=https://openrouter.ai/api -v /tmp/claude:/claude -v /etc/passwd:/etc/passwd \
--user podman myregistry.adm13:443/local/claude:20260429  /opt/bin/claude --verbose -p --output-format stream-json --dangerously-skip-permissions \
"Write a one-line Python function that returns the factorial of a number" \
| jq -r 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text'

