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
