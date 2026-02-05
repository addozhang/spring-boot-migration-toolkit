#!/bin/bash
# prepare-validation.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Preparing Validation ==="

# Create validation directory
mkdir -p .migration-validation

# 1. Record current dependency tree
echo "📋 Recording dependency tree..."
mvn dependency:tree > .migration-validation/dependencies-before.txt 2>&1

# 2. Attempt compilation (record results, don't interrupt)
echo "🔨 Attempting compilation..."
mvn clean compile > .migration-validation/compile-before.txt 2>&1
COMPILE_STATUS=$?
if [ $COMPILE_STATUS -eq 0 ]; then
    echo "✓ Compilation successful"
else
    echo "⚠ Compilation failed (this is normal, will be fixed after migration)"
fi

# 3. Run tests (record results, don't interrupt)
echo "🧪 Running tests..."
mvn test > .migration-validation/test-before.txt 2>&1
TEST_STATUS=$?
if [ $TEST_STATUS -eq 0 ]; then
    echo "✓ Tests passed"
else
    echo "⚠ Tests failed"
fi

# 4. Create backup branch
if [ -d .git ]; then
    echo "📦 Creating backup branch..."
    BACKUP_BRANCH="backup-before-migration-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BACKUP_BRANCH"
    git add -A
    git commit -m "Backup before Spring Boot 3 migration" --allow-empty
    git checkout -
    echo "✓ Backup branch: $BACKUP_BRANCH"
    echo "BACKUP_BRANCH=$BACKUP_BRANCH" >> .migration-validation/info.txt
fi

echo "✅ Validation preparation completed"
echo ""
echo "Pre-migration status:"
echo "  - Compilation: $([ $COMPILE_STATUS -eq 0 ] && echo '✓' || echo '✗')"
echo "  - Tests: $([ $TEST_STATUS -eq 0 ] && echo '✓' || echo '✗')"
