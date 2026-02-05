#!/bin/bash
# prepare-validation.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== 准备验证方案 ==="

# 创建验证目录
mkdir -p .migration-validation

# 1. 记录当前依赖树
echo "📋 记录依赖树..."
mvn dependency:tree > .migration-validation/dependencies-before.txt 2>&1

# 2. 尝试编译（记录结果，不中断）
echo "🔨 尝试编译..."
mvn clean compile > .migration-validation/compile-before.txt 2>&1
COMPILE_STATUS=$?
if [ $COMPILE_STATUS -eq 0 ]; then
    echo "✓ 编译成功"
else
    echo "⚠ 编译失败（这是正常的，迁移后会修复）"
fi

# 3. 运行测试（记录结果，不中断）
echo "🧪 运行测试..."
mvn test > .migration-validation/test-before.txt 2>&1
TEST_STATUS=$?
if [ $TEST_STATUS -eq 0 ]; then
    echo "✓ 测试通过"
else
    echo "⚠ 测试失败"
fi

# 4. 创建备份分支
if [ -d .git ]; then
    echo "📦 创建备份分支..."
    BACKUP_BRANCH="backup-before-migration-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BACKUP_BRANCH"
    git add -A
    git commit -m "Backup before Spring Boot 3 migration" --allow-empty
    git checkout -
    echo "✓ 备份分支: $BACKUP_BRANCH"
    echo "BACKUP_BRANCH=$BACKUP_BRANCH" >> .migration-validation/info.txt
fi

echo "✅ 验证方案准备完成"
echo ""
echo "迁移前状态:"
echo "  - 编译: $([ $COMPILE_STATUS -eq 0 ] && echo '✓' || echo '✗')"
echo "  - 测试: $([ $TEST_STATUS -eq 0 ] && echo '✓' || echo '✗')"
