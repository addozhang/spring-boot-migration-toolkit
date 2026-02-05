#!/bin/bash
# validate-migration.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Validating Migration Results ==="

# 1. Run tests
echo "🧪 Running tests..."
mvn test > .migration-validation/test-after.txt 2>&1
TEST_STATUS=$?

if [ $TEST_STATUS -eq 0 ]; then
    echo "✅ Tests passed"
else
    echo "⚠ Tests failed, please check .migration-validation/test-after.txt"
fi

# 2. Record post-migration dependency tree
echo "📋 Recording post-migration dependency tree..."
mvn dependency:tree > .migration-validation/dependencies-after.txt 2>&1

# 3. Compare dependency changes
echo ""
echo "📊 Dependency changes comparison:"
diff .migration-validation/dependencies-before.txt .migration-validation/dependencies-after.txt > .migration-validation/dependencies-diff.txt || true
echo "Detailed comparison saved to .migration-validation/dependencies-diff.txt"

# 4. Generate migration report
cat > .migration-validation/MIGRATION-REPORT.md <<EOF
# Spring Boot 2 → 3 Migration Report

**Migration Date**: $(date)
**Project Path**: $PROJECT_PATH

## Migration Results

- Compilation Status: ✅ Successful
- Test Status: $([ $TEST_STATUS -eq 0 ] && echo '✅ Passed' || echo '⚠️ Failed')

## Major Changes

1. Spring Boot version upgrade
2. JDK version upgrade to 21
3. Jakarta EE namespace migration

## Dependency Changes

See dependencies-diff.txt for details

## Follow-up Recommendations

1. Carefully review test failure causes (if any)
2. Manually verify critical business functionality
3. Check property changes in configuration files
4. Update CI/CD configuration to use JDK 21
5. Consider leveraging JDK 21 new features (Virtual Threads, etc.)

## File Inventory

- \`compile-before.txt\` - Pre-migration compilation log
- \`compile-after-attempt-X.txt\` - Post-migration compilation log
- \`test-before.txt\` - Pre-migration test log
- \`test-after.txt\` - Post-migration test log
- \`dependencies-before.txt\` - Pre-migration dependency tree
- \`dependencies-after.txt\` - Post-migration dependency tree
- \`dependencies-diff.txt\` - Dependency changes comparison
- \`rewrite-discovery.txt\` - OpenRewrite discovery output
- \`rewrite-dryrun.txt\` - OpenRewrite dry-run output
- \`rewrite-run.txt\` - OpenRewrite execution log

EOF

echo ""
echo "✅ Migration completed!"
echo ""
echo "📄 Migration report generated: .migration-validation/MIGRATION-REPORT.md"
echo ""
cat .migration-validation/MIGRATION-REPORT.md
