#!/bin/bash
# apply-rewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Applying OpenRewrite Changes ==="

# Run rewrite
mvn rewrite:run | tee .migration-validation/rewrite-run.txt

REWRITE_STATUS=$?

if [ $REWRITE_STATUS -eq 0 ]; then
    echo "✅ OpenRewrite executed successfully"
else
    echo "❌ OpenRewrite execution failed"
    exit 1
fi

# Display change statistics
echo ""
echo "📊 Change statistics:"
git diff --stat
