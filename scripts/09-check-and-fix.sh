#!/bin/bash
# check-and-fix.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Checking Compilation Results ==="

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo ""
    echo "Attempt #$((RETRY_COUNT + 1)): Compiling project..."
    
    mvn clean compile > .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt 2>&1
    COMPILE_STATUS=$?
    
    if [ $COMPILE_STATUS -eq 0 ]; then
        echo "✅ Compilation successful!"
        break
    else
        echo "❌ Compilation failed"
        echo ""
        echo "Error log (last 30 lines):"
        tail -n 30 .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt
        echo ""
        
        # Analyze common issues
        ERROR_LOG=$(cat .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt)
        
        # Check for incomplete javax -> jakarta migration
        if echo "$ERROR_LOG" | grep -q "package javax"; then
            echo "💡 javax package references detected, some dependencies may need manual handling"
            echo "Recommendation: Check if third-party dependencies support Jakarta EE"
        fi
        
        # Check Hibernate Dialect
        if echo "$ERROR_LOG" | grep -q "Dialect"; then
            echo "💡 Dialect-related error detected"
            echo "Recommendation: Hibernate 6 removed version-specific Dialects, use generic Dialect"
        fi
        
        # Check configuration properties
        if echo "$ERROR_LOG" | grep -q "property"; then
            echo "💡 Configuration property error detected"
            echo "Recommendation: Check property name changes in application.properties/yml"
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo ""
            read -p "Attempt manual fix and recompile? (y/n): " MANUAL_FIX
            if [ "$MANUAL_FIX" != "y" ]; then
                echo "❌ Fix cancelled by user"
                exit 1
            fi
        fi
    fi
done

if [ $COMPILE_STATUS -ne 0 ]; then
    echo ""
    echo "❌ Compilation failed, maximum retry attempts reached"
    echo "Please manually check and fix the issues, then re-run the validation script"
    exit 1
fi
