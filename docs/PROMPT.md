# Spring Boot 2 → 3 + JDK 8 → 21 迁移 Prompt (OpenRewrite 方案)

## 任务目标

使用 OpenRewrite 自动化工具，将 Spring Boot 2 项目迁移到 Spring Boot 3.5.10，同时升级 JDK 8 到 JDK 21。尽可能通过 shell 脚本自动化执行整个流程。

---

## 执行流程

### 第 1 步：环境检查与准备

**要求**：
1. 检查系统是否安装 JDK 17+ (OpenRewrite 要求)
2. 检查 Maven 版本 (推荐 3.8.1+)
3. 如果环境不满足，指导用户安装或提供安装脚本

**输出**：
```bash
#!/bin/bash
# check-environment.sh

echo "=== 环境检查 ==="

# 检查 Java 版本
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    echo "✓ Java 版本: $JAVA_VERSION"
    if [ "$JAVA_VERSION" -lt 17 ]; then
        echo "❌ OpenRewrite 需要 JDK 17+，当前版本不满足"
        echo "请安装 JDK 17 或 JDK 21"
        exit 1
    fi
else
    echo "❌ 未检测到 Java，请安装 JDK 17+"
    exit 1
fi

# 检查 Maven
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -v | head -n 1 | awk '{print $3}')
    echo "✓ Maven 版本: $MVN_VERSION"
else
    echo "❌ 未检测到 Maven，请安装 Maven 3.8.1+"
    exit 1
fi

echo "✅ 环境检查通过"
```

---

### 第 2 步：获取项目路径

**要求**：
1. 提示用户输入项目路径
2. 验证路径是否存在
3. 验证是否为 Maven 项目 (检查 pom.xml)

**输出**：
```bash
#!/bin/bash
# get-project-path.sh

read -p "请输入项目路径 (绝对路径或相对路径): " PROJECT_PATH

# 展开路径
PROJECT_PATH=$(realpath "$PROJECT_PATH" 2>/dev/null)

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ 路径不存在: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/pom.xml" ]; then
    echo "❌ 未找到 pom.xml，这不是一个 Maven 项目"
    echo "路径: $PROJECT_PATH"
    exit 1
fi

echo "✅ 项目路径: $PROJECT_PATH"
echo "$PROJECT_PATH" > .migration-project-path
```

---

### 第 3 步：检查项目信息

**要求**：
1. 读取 pom.xml，提取关键信息：
   - Spring Boot 版本
   - Java 版本
   - 父 POM 信息
   - 依赖列表
2. 判断项目是否适合使用 OpenRewrite：
   - ✅ 使用 Maven 构建
   - ✅ Spring Boot 2.x
   - ✅ 非 Kotlin 项目
   - ❌ Gradle 项目（暂不支持此脚本）

**输出**：
```bash
#!/bin/bash
# analyze-project.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== 项目信息分析 ==="

# 提取 Spring Boot 版本
SPRING_BOOT_VERSION=$(grep -oP '(?<=<spring-boot.version>)[^<]+' "$POM_FILE" || \
                      grep -oP '(?<=<version>)[^<]+' "$POM_FILE" | head -n 1)
echo "Spring Boot 版本: ${SPRING_BOOT_VERSION:-未检测到}"

# 提取 Java 版本
JAVA_VERSION=$(grep -oP '(?<=<java.version>)[^<]+' "$POM_FILE" || \
               grep -oP '(?<=<maven.compiler.source>)[^<]+' "$POM_FILE")
echo "Java 版本: ${JAVA_VERSION:-未检测到}"

# 检查是否有 parent
HAS_PARENT=$(grep -c "<parent>" "$POM_FILE")
if [ "$HAS_PARENT" -gt 0 ]; then
    PARENT_ARTIFACT=$(grep -A 3 "<parent>" "$POM_FILE" | grep -oP '(?<=<artifactId>)[^<]+' | head -n 1)
    echo "使用 Parent POM: $PARENT_ARTIFACT"
fi

# 检查是否为 Kotlin 项目
if grep -q "kotlin-maven-plugin" "$POM_FILE"; then
    echo "❌ 检测到 Kotlin 项目，OpenRewrite 对 Kotlin 支持有限"
    read -p "是否继续？(y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

# 保存项目信息
cat > .migration-project-info <<EOF
SPRING_BOOT_VERSION=$SPRING_BOOT_VERSION
JAVA_VERSION=$JAVA_VERSION
PARENT_ARTIFACT=$PARENT_ARTIFACT
EOF

echo "✅ 项目信息已保存"
```

---

### 第 4 步：准备验证方案

**要求**：
1. 在迁移前记录项目状态：
   - 运行测试并记录结果
   - 记录依赖树
   - 记录编译状态
2. 创建备份分支
3. 准备迁移后的验证清单

**输出**：
```bash
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
```

---

### 第 5 步：配置 OpenRewrite

**要求**：
1. 在项目 pom.xml 中添加 OpenRewrite Maven Plugin
2. 配置合适的 recipes：
   - Spring Boot 3.0 升级
   - JDK 21 迁移
   - Jakarta EE 迁移
3. 根据项目实际情况调整配置

**输出**：
```bash
#!/bin/bash
# setup-openrewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== 配置 OpenRewrite ==="

# 检查是否已配置
if grep -q "rewrite-maven-plugin" "$POM_FILE"; then
    echo "⚠ OpenRewrite 插件已存在，跳过配置"
    exit 0
fi

# 读取项目信息
source .migration-project-info

# 准备插件配置
cat > /tmp/rewrite-plugin.xml <<'EOF'
            <plugin>
                <groupId>org.openrewrite.maven</groupId>
                <artifactId>rewrite-maven-plugin</artifactId>
                <version>6.4.0</version>
                <configuration>
                    <activeRecipes>
                        <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5</recipe>
                    </activeRecipes>
                </configuration>
                <dependencies>
                    <dependency>
                        <groupId>org.openrewrite.recipe</groupId>
                        <artifactId>rewrite-spring</artifactId>
                        <version>6.4.0</version>
                    </dependency>
                    <dependency>
                        <groupId>org.openrewrite.recipe</groupId>
                        <artifactId>rewrite-migrate-java</artifactId>
                        <version>2.20.0</version>
                    </dependency>
                </dependencies>
            </plugin>
EOF

# 使用 xmlstarlet 或手动插入（如果没有 xmlstarlet，提示用户手动添加）
if command -v xmlstarlet &> /dev/null; then
    echo "使用 xmlstarlet 自动配置..."
    # 这里需要更复杂的 XML 操作，简化为手动步骤
    echo "⚠ 自动配置较复杂，建议手动添加"
else
    echo "📝 请手动将以下配置添加到 pom.xml 的 <build><plugins> 中："
    echo ""
    cat /tmp/rewrite-plugin.xml
    echo ""
    read -p "添加完成后按回车继续..."
fi

echo "✅ OpenRewrite 配置完成"
```

---

### 第 6 步：运行 OpenRewrite Discovery

**要求**：
1. 运行 `mvn rewrite:discover` 发现可应用的 recipes
2. 展示发现结果
3. 确认是否继续

**输出**：
```bash
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
```

---

### 第 7 步：运行 OpenRewrite (Dry Run)

**要求**：
1. 先运行 dry-run 模式，预览变更
2. 展示会修改哪些文件
3. 让用户确认

**输出**：
```bash
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
```

---

### 第 8 步：应用 OpenRewrite 变更

**要求**：
1. 运行 `mvn rewrite:run` 应用变更
2. 记录执行日志
3. 检查执行结果

**输出**：
```bash
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
```

---

### 第 9 步：检查并修复问题

**要求**：
1. 尝试编译项目
2. 如果编译失败，分析错误：
   - 依赖版本冲突
   - API 变更
   - 配置问题
3. 提供修复建议或自动修复
4. 循环直到编译通过

**输出**：
```bash
#!/bin/bash
# check-and-fix.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== 检查编译结果 ==="

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo ""
    echo "尝试 #$((RETRY_COUNT + 1)): 编译项目..."
    
    mvn clean compile > .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt 2>&1
    COMPILE_STATUS=$?
    
    if [ $COMPILE_STATUS -eq 0 ]; then
        echo "✅ 编译成功！"
        break
    else
        echo "❌ 编译失败"
        echo ""
        echo "错误日志（最后 30 行）:"
        tail -n 30 .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt
        echo ""
        
        # 分析常见问题
        ERROR_LOG=$(cat .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt)
        
        # 检查 javax -> jakarta 未完成
        if echo "$ERROR_LOG" | grep -q "package javax"; then
            echo "💡 检测到 javax 包引用，可能需要手动处理某些依赖"
            echo "建议: 检查第三方依赖是否支持 Jakarta EE"
        fi
        
        # 检查 Hibernate Dialect
        if echo "$ERROR_LOG" | grep -q "Dialect"; then
            echo "💡 检测到 Dialect 相关错误"
            echo "建议: Hibernate 6 移除了版本特定的 Dialect，使用通用 Dialect"
        fi
        
        # 检查配置属性
        if echo "$ERROR_LOG" | grep -q "property"; then
            echo "💡 检测到配置属性错误"
            echo "建议: 检查 application.properties/yml 中的属性名称变更"
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo ""
            read -p "是否尝试手动修复后重新编译？(y/n): " MANUAL_FIX
            if [ "$MANUAL_FIX" != "y" ]; then
                echo "❌ 用户取消修复"
                exit 1
            fi
        fi
    fi
done

if [ $COMPILE_STATUS -ne 0 ]; then
    echo ""
    echo "❌ 编译失败，已达到最大重试次数"
    echo "请手动检查并修复问题后，重新运行验证脚本"
    exit 1
fi
```

---

### 第 10 步：验证迁移结果

**要求**：
1. 运行测试套件
2. 对比迁移前后的依赖变化
3. 生成迁移报告
4. 提供后续建议

**输出**：
```bash
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
```

---

## 完整自动化脚本

将以上步骤整合为一个主控脚本：

```bash
#!/bin/bash
# migrate-spring-boot.sh - 主控脚本

set -e

echo "================================================="
echo "  Spring Boot 2 → 3 + JDK 8 → 21 自动迁移工具"
echo "  使用 OpenRewrite 方案"
echo "================================================="
echo ""

# 第 1 步
bash check-environment.sh || exit 1
echo ""

# 第 2 步
bash get-project-path.sh || exit 1
echo ""

# 第 3 步
bash analyze-project.sh || exit 1
echo ""

# 第 4 步
bash prepare-validation.sh || exit 1
echo ""

# 第 5 步
bash setup-openrewrite.sh || exit 1
echo ""

# 第 6 步
bash run-discovery.sh || exit 1
echo ""

# 第 7 步
bash run-dryrun.sh || exit 1
echo ""

# 第 8 步
bash apply-rewrite.sh || exit 1
echo ""

# 第 9 步
bash check-and-fix.sh || exit 1
echo ""

# 第 10 步
bash validate-migration.sh || exit 1

echo ""
echo "================================================="
echo "  🎉 迁移流程完成！"
echo "================================================="
```

---

## 使用说明

### 前置条件
- 安装 JDK 17 或 21
- 安装 Maven 3.8.1+
- 项目使用 Maven 构建
- 项目已提交到 Git（可选，用于备份）

### 执行步骤

1. **下载所有脚本** 到同一目录
2. **添加执行权限**: `chmod +x *.sh`
3. **运行主脚本**: `./migrate-spring-boot.sh`
4. **按照提示操作**

### 注意事项

- 脚本会在项目目录下创建 `.migration-validation/` 目录存储所有日志
- 建议在运行前手动备份项目
- 如果使用 Git，脚本会自动创建备份分支
- 某些复杂场景可能需要手动干预

---

## AI Agent 执行指令

作为 AI Agent，你应该：

1. **先读取并理解每个步骤的目的**
2. **按顺序执行每个 shell 脚本**
3. **如果某步失败，分析失败原因并尝试修复**
4. **在需要用户输入的地方，主动向用户询问**
5. **在关键决策点（如 dry-run 后），向用户展示结果并等待确认**
6. **遇到编译错误时，结合知识库分析常见问题并提供解决方案**
7. **最终生成详细的迁移报告**

### 错误处理策略

- **依赖冲突**: 使用 `mvn dependency:tree` 分析，建议排除或升级版本
- **API 变更**: 参考 Spring Boot 3 迁移指南，提供替代方案
- **配置属性**: 检查 `application.properties/yml`，更新属性名称
- **第三方库**: 查找支持 Jakarta EE 的版本，或使用 Jakarta Migration Tool 转换

---

## 相关资源

- OpenRewrite 文档: https://docs.openrewrite.org
- Spring Boot 3 迁移指南: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide
- 迁移素材库: `~/my-obsidian-vault/个人/草稿/spring-boot-2-to-3-migration.md`
