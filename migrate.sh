#!/bin/bash
# migrate.sh - Main migration orchestrator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH_ARG="$1"

echo "================================================="
echo "  Spring Boot 2 → 3 + JDK 8 → 21 Migration Tool"
echo "  Using OpenRewrite"
echo "================================================="
echo ""

# Step 1
echo "Step 1/10: Environment Check"
bash "$SCRIPT_DIR/scripts/01-check-environment.sh" || exit 1
echo ""

# Step 2
echo "Step 2/10: Get Project Path"
bash "$SCRIPT_DIR/scripts/02-get-project-path.sh" "$PROJECT_PATH_ARG" || exit 1
echo ""

# Step 3
echo "Step 3/10: Analyze Project"
bash "$SCRIPT_DIR/scripts/03-analyze-project.sh" || exit 1
echo ""

# Step 4
echo "Step 4/10: Prepare Validation"
bash "$SCRIPT_DIR/scripts/04-prepare-validation.sh" || exit 1
echo ""

# Step 5
echo "Step 5/10: Configure OpenRewrite"
bash "$SCRIPT_DIR/scripts/05-setup-openrewrite.sh" || exit 1
echo ""

# Step 6
echo "Step 6/10: Run Discovery"
bash "$SCRIPT_DIR/scripts/06-run-discovery.sh" || exit 1
echo ""

# Step 7
echo "Step 7/10: Run Dry Run"
bash "$SCRIPT_DIR/scripts/07-run-dryrun.sh" || exit 1
echo ""

# Step 8
echo "Step 8/10: Apply Changes"
bash "$SCRIPT_DIR/scripts/08-apply-rewrite.sh" || exit 1
echo ""

# Step 9
echo "Step 9/10: Check and Fix"
bash "$SCRIPT_DIR/scripts/09-check-and-fix.sh" || exit 1
echo ""

# Step 10
echo "Step 10/10: Validate Results"
bash "$SCRIPT_DIR/scripts/10-validate-migration.sh" || exit 1

echo ""
echo "================================================="
echo "  🎉 Migration Completed!"
echo "================================================="
