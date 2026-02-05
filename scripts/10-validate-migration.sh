#!/bin/bash
# validate-migration.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== 验证迁移结果 ==="

# 1. 运行测试
echo "🧪 运行测试..."
mvn test > .migration-validation/test-after.txt 2>&1
TEST_STATUS=$?

if [ $TEST_STATUS -eq 0 ]; then
    echo "✅ 测试通过"
else
    echo "⚠ 测试失败，请检查 .migration-validation/test-after.txt"
fi

# 2. 记录迁移后的依赖树
echo "📋 记录迁移后依赖树..."
mvn dependency:tree > .migration-validation/dependencies-after.txt 2>&1

# 3. 对比依赖变化
echo ""
echo "📊 依赖变化对比:"
diff .migration-validation/dependencies-before.txt .migration-validation/dependencies-after.txt > .migration-validation/dependencies-diff.txt || true
echo "详细对比已保存到 .migration-validation/dependencies-diff.txt"

# 4. 生成迁移报告
cat > .migration-validation/MIGRATION-REPORT.md <<EOF
# Spring Boot 2 → 3 迁移报告

**迁移时间**: $(date)
**项目路径**: $PROJECT_PATH

## 迁移结果

- 编译状态: ✅ 成功
- 测试状态: $([ $TEST_STATUS -eq 0 ] && echo '✅ 通过' || echo '⚠️ 失败')

## 主要变更

1. Spring Boot 版本升级
2. JDK 版本升级到 21
3. Jakarta EE 命名空间迁移

## 依赖变化

详见 dependencies-diff.txt

## 后续建议

1. 仔细检查测试失败的原因（如有）
2. 手动验证关键业务功能
3. 检查配置文件中的属性变更
4. 更新 CI/CD 配置以使用 JDK 21
5. 考虑利用 JDK 21 的新特性（Virtual Threads 等）

## 文件清单

- \`compile-before.txt\` - 迁移前编译日志
- \`compile-after-attempt-X.txt\` - 迁移后编译日志
- \`test-before.txt\` - 迁移前测试日志
- \`test-after.txt\` - 迁移后测试日志
- \`dependencies-before.txt\` - 迁移前依赖树
- \`dependencies-after.txt\` - 迁移后依赖树
- \`dependencies-diff.txt\` - 依赖变化对比
- \`rewrite-discovery.txt\` - OpenRewrite discovery 输出
- \`rewrite-dryrun.txt\` - OpenRewrite dry-run 输出
- \`rewrite-run.txt\` - OpenRewrite 执行日志

EOF

echo ""
echo "✅ 迁移完成！"
echo ""
echo "📄 迁移报告已生成: .migration-validation/MIGRATION-REPORT.md"
echo ""
cat .migration-validation/MIGRATION-REPORT.md
