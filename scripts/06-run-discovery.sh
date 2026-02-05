#!/bin/bash
# run-discovery.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== OpenRewrite Discovery ==="

# 运行 discovery
mvn rewrite:discover -Dverbose=true | tee .migration-validation/rewrite-discovery.txt

echo ""
echo "📊 Discovery 完成，请检查上述输出"
read -p "是否继续执行迁移？(y/n): " CONTINUE

if [ "$CONTINUE" != "y" ]; then
    echo "❌ 用户取消迁移"
    exit 1
fi
