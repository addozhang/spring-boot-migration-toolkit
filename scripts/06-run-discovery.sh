#!/bin/bash
# run-discovery.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== OpenRewrite Discovery ==="

# Run discovery
mvn rewrite:discover -Dverbose=true | tee .migration-validation/rewrite-discovery.txt

echo ""
echo "📊 Discovery completed, please review the output above"
read -p "Continue with migration? (y/n): " CONTINUE

if [ "$CONTINUE" != "y" ]; then
    echo "❌ Migration cancelled by user"
    exit 1
fi
