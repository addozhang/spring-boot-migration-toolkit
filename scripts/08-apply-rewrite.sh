#!/bin/bash
# apply-rewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== 应用 OpenRewrite 变更 ==="

# 运行 rewrite
mvn rewrite:run | tee .migration-validation/rewrite-run.txt

REWRITE_STATUS=$?

if [ $REWRITE_STATUS -eq 0 ]; then
    echo "✅ OpenRewrite 执行成功"
else
    echo "❌ OpenRewrite 执行失败"
    exit 1
fi

# 显示变更统计
echo ""
echo "📊 变更统计:"
git diff --stat
