#!/bin/bash
# run-dryrun.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== OpenRewrite Dry Run (Preview Mode) ==="

# Run dry-run
mvn rewrite:dryRun | tee .migration-validation/rewrite-dryrun.txt

echo ""
echo "📝 Dry Run completed, please check .migration-validation/rewrite-dryrun.txt"
echo "Preview of changed files has been saved"
echo ""
read -p "Confirm applying these changes? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "❌ Changes cancelled by user"
    exit 1
fi
