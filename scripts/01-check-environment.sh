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
