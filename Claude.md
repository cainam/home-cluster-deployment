- Gentoo install in container image
(mypyenv) k8s-4-int /tmp/claude # cat .claude/settings.json
{
  "theme": "auto",
   "env": {
    "ANTHROPIC_BASE_URL": "https://openrouter.ai/api/v1"
  },
  "model": "meta-llama/llama-3.3-70b-instruct:free",
  "smallModel": "meta-llama/llama-3.1-8b-instruct:free"
}
(mypyenv) k8s-4-int /tmp/claude # vi .claude/settings.json
(mypyenv) k8s-4-int /tmp/claude # podman run -it --rm -e HOME=/claude -e ANTHROPIC_API_KEY="xxx"  -v /tmp/claude:/claude 7ad55a8e7db1 /opt/bin/claude
╭─── Claude Code v2.1.121 ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                    │ Tips for getting started                                                                                                                                                 │
│                    Welcome back!                   │ Run /init to create a CLAUDE.md file with instructions for Claude                                                                                                        │
│                                                    │ ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │
│                       ▐▛███▜▌                      │ What's new                                                                                                                                                               │
│                      ▝▜█████▛▘                     │ Added plugin dependency enforcement: `claude plugin disable` now refuses when another enabled plugin depends on the target (with a copy-pasteable disable-chain hint), … │
│                        ▘▘ ▝▝                       │ Added projected context cost (per-turn and per-invocation token estimates) to the `/plugin` marketplace browse pane                                                      │
│                                                    │ Added `worktree.bgIsolation: "none"` setting to let background sessions edit the working copy directly without `EnterWorktree`, for repos where worktrees are impractic… │
│ meta-llama/llama-3.3-70b-inst… · API Usage Billing │ /release-notes for more                                                                                                                                                  │
│                         /                          │                                                                                                                                                                          │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

❯ /init
  ⎿  API Error: Request rejected (429) · Provider returned error

