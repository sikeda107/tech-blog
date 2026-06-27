# claude-code-hook-review

Claude Code の `PostToolUse` フックで、`.claude/skills` / `.claude/rules` / `.claude/commands` を
編集したら **必ず公式記法レビューを促す** サンプルです。

関連記事: https://zenn.dev/sikeda107/articles/claude-code-hook-review

## 構成

```
.claude/
├── settings.json                     # PostToolUse に Hook を登録
└── hooks/
    └── review-skill-rule-format.sh   # 対象パスを編集したら additionalContext を注入
```

## 動作確認（パイプテスト）

実際にファイルを編集しなくても、本体が渡す JSON を模した入力を流せば挙動を確認できます。

```bash
# 対象パス → additionalContext を含む JSON が出る
echo '{"tool_input":{"file_path":".claude/skills/foo/SKILL.md"}}' \
  | bash .claude/hooks/review-skill-rule-format.sh

# 対象外パス → 何も出ない（exit 0）
echo '{"tool_input":{"file_path":"src/index.ts"}}' \
  | bash .claude/hooks/review-skill-rule-format.sh
```

`jq -e` で JSON として妥当か、スキーマが期待通りかも確認できます。

```bash
echo '{"tool_input":{"file_path":".claude/rules/x.md"}}' \
  | bash .claude/hooks/review-skill-rule-format.sh \
  | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"'
```
