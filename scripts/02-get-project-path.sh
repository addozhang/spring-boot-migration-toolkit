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
