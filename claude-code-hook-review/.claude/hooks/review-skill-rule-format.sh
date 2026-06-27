#!/usr/bin/env bash
# PostToolUse フック:
#   .claude/skills / .claude/rules / .claude/commands 配下のファイルを編集したら、
#   Claude Code 公式仕様と照合してレビューするようリマインダ（additionalContext）を注入する。
#   対象外のパスでは何も出力しない（exit 0）。
set -euo pipefail

# 本体（CLI）が stdin で渡してくる JSON から、編集対象ファイルのパスを取り出す。
#   抽出は -r（raw output / ダブルクオート無し）。入力ありなので -n は付けない。
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

case "$file" in
  *.claude/skills/* | *.claude/rules/* | *.claude/commands/*)
    # 固定の JSON を出すだけなので -n（入力なし）、フック出力は JSON 解釈されるので -c（1行）。
    jq -nc '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: "編集した .claude/skills / .claude/rules / .claude/commands のファイルが Claude Code 公式仕様に準拠しているか、https://code.claude.com/docs/en/skills.md など公式ドキュメントと照合してレビューすること。SKILL.md は frontmatter（description は推奨で when_to_use 込み 1,536 文字以内、公式フィールドのみ使用、name は表示用ラベルでディレクトリ名がコマンド名になる）とディレクトリ構成（.claude/skills/<name>/SKILL.md）を確認する。.claude/commands/<name>.md はカスタムコマンド（skill と同等）で、frontmatter は description / argument-hint / allowed-tools などの公式フィールドのみ使用し、ファイル名がコマンド名になる点を確認する。問題があれば指摘・修正する。"
      }
    }'
    ;;
esac

# exit 0 のときだけ、本体は stdout を JSON として解釈する。
exit 0
