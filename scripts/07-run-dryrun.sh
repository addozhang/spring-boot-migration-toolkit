#!/bin/bash
# run-dryrun.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== OpenRewrite Dry Run (预览模式) ==="

# 运行 dry-run
mvn rewrite:dryRun | tee .migration-validation/rewrite-dryrun.txt

echo ""
echo "📝 Dry Run 完成，请查看 .migration-validation/rewrite-dryrun.txt"
echo "预览变更的文件列表已保存"
echo ""
read -p "确认应用这些变更？(y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "❌ 用户取消应用变更"
    exit 1
fi
