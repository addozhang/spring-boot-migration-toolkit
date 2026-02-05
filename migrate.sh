#!/bin/bash
# migrate.sh - 主控脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================="
echo "  Spring Boot 2 → 3 + JDK 8 → 21 自动迁移工具"
echo "  使用 OpenRewrite 方案"
echo "================================================="
echo ""

# 第 1 步
echo "步骤 1/10: 环境检查"
bash "$SCRIPT_DIR/scripts/01-check-environment.sh" || exit 1
echo ""

# 第 2 步
echo "步骤 2/10: 获取项目路径"
bash "$SCRIPT_DIR/scripts/02-get-project-path.sh" || exit 1
echo ""

# 第 3 步
echo "步骤 3/10: 分析项目信息"
bash "$SCRIPT_DIR/scripts/03-analyze-project.sh" || exit 1
echo ""

# 第 4 步
echo "步骤 4/10: 准备验证方案"
bash "$SCRIPT_DIR/scripts/04-prepare-validation.sh" || exit 1
echo ""

# 第 5 步
echo "步骤 5/10: 配置 OpenRewrite"
bash "$SCRIPT_DIR/scripts/05-setup-openrewrite.sh" || exit 1
echo ""

# 第 6 步
echo "步骤 6/10: 运行 Discovery"
bash "$SCRIPT_DIR/scripts/06-run-discovery.sh" || exit 1
echo ""

# 第 7 步
echo "步骤 7/10: 运行 Dry Run"
bash "$SCRIPT_DIR/scripts/07-run-dryrun.sh" || exit 1
echo ""

# 第 8 步
echo "步骤 8/10: 应用变更"
bash "$SCRIPT_DIR/scripts/08-apply-rewrite.sh" || exit 1
echo ""

# 第 9 步
echo "步骤 9/10: 检查并修复"
bash "$SCRIPT_DIR/scripts/09-check-and-fix.sh" || exit 1
echo ""

# 第 10 步
echo "步骤 10/10: 验证结果"
bash "$SCRIPT_DIR/scripts/10-validate-migration.sh" || exit 1

echo ""
echo "================================================="
echo "  🎉 迁移流程完成！"
echo "================================================="
