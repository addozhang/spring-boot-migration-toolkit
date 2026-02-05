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
