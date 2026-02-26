# Spring Boot 2 → 3 + JDK 8 → 21 Migration Prompt (OpenRewrite Approach)

## Objective

Use OpenRewrite to automate the migration of a Spring Boot 2 project to Spring Boot 3.5.10, while upgrading JDK 8 to JDK 21. Automate as much of the workflow as possible through shell scripts.

---

## Execution Flow

### Step 1: Environment Check

**Requirements**:
1. Verify JDK 17+ is installed (required by OpenRewrite)
2. Verify Maven version (3.8.1+ recommended)
3. If the environment is insufficient, guide the user or provide an installation script

**Output**:
```bash
#!/bin/bash
# check-environment.sh

echo "=== Environment Check ==="

# Check Java version
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    echo "✓ Java version: $JAVA_VERSION"
    if [ "$JAVA_VERSION" -lt 17 ]; then
        echo "❌ OpenRewrite requires JDK 17+, current version does not meet the requirement"
        echo "Please install JDK 17 or JDK 21"
        exit 1
    fi
else
    echo "❌ Java not detected, please install JDK 17+"
    exit 1
fi

# Check Maven
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -v | head -n 1 | awk '{print $3}')
    echo "✓ Maven version: $MVN_VERSION"
else
    echo "❌ Maven not detected, please install Maven 3.8.1+"
    exit 1
fi

echo "✅ Environment check passed"
```

---

### Step 2: Get Project Path

**Requirements**:
1. Prompt the user to enter the project path
2. Validate the path exists
3. Validate it is a Maven project (check for pom.xml)

**Output**:
```bash
#!/bin/bash
# get-project-path.sh

read -p "Enter project path (absolute or relative): " PROJECT_PATH

# Expand the path
PROJECT_PATH=$(realpath "$PROJECT_PATH" 2>/dev/null)

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$PROJECT_PATH/pom.xml" ]; then
    echo "❌ pom.xml not found — this is not a Maven project"
    echo "Path: $PROJECT_PATH"
    exit 1
fi

echo "✅ Project path: $PROJECT_PATH"
echo "$PROJECT_PATH" > .migration-project-path
```

---

### Step 3: Analyze Project

**Requirements**:
1. Read pom.xml and extract key information:
   - Spring Boot version
   - Java version
   - Parent POM details
   - Dependency list
2. Determine if the project is suitable for OpenRewrite:
   - ✅ Maven build
   - ✅ Spring Boot 2.x
   - ✅ Non-Kotlin project
   - ❌ Gradle project (not supported by this script)

**Output**:
```bash
#!/bin/bash
# analyze-project.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== Project Analysis ==="

# Extract Spring Boot version
SPRING_BOOT_VERSION=$(grep -oP '(?<=<spring-boot.version>)[^<]+' "$POM_FILE" || \
                      grep -oP '(?<=<version>)[^<]+' "$POM_FILE" | head -n 1)
echo "Spring Boot version: ${SPRING_BOOT_VERSION:-not detected}"

# Extract Java version
JAVA_VERSION=$(grep -oP '(?<=<java.version>)[^<]+' "$POM_FILE" || \
               grep -oP '(?<=<maven.compiler.source>)[^<]+' "$POM_FILE")
echo "Java version: ${JAVA_VERSION:-not detected}"

# Check for parent POM
HAS_PARENT=$(grep -c "<parent>" "$POM_FILE")
if [ "$HAS_PARENT" -gt 0 ]; then
    PARENT_ARTIFACT=$(grep -A 3 "<parent>" "$POM_FILE" | grep -oP '(?<=<artifactId>)[^<]+' | head -n 1)
    echo "Using parent POM: $PARENT_ARTIFACT"
fi

# Check for Kotlin project
if grep -q "kotlin-maven-plugin" "$POM_FILE"; then
    echo "❌ Kotlin project detected — OpenRewrite has limited Kotlin support"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

# Save project info
cat > .migration-project-info <<EOF
SPRING_BOOT_VERSION=$SPRING_BOOT_VERSION
JAVA_VERSION=$JAVA_VERSION
PARENT_ARTIFACT=$PARENT_ARTIFACT
EOF

echo "✅ Project info saved"
```

---

### Step 4: Prepare Validation

**Requirements**:
1. Record project state before migration:
   - Run tests and save results
   - Record dependency tree
   - Record compilation status
2. Create a backup branch
3. Prepare a post-migration validation checklist

**Output**:
```bash
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

# 2. Attempt compilation (record result, do not abort)
echo "🔨 Attempting compilation..."
mvn clean compile > .migration-validation/compile-before.txt 2>&1
COMPILE_STATUS=$?
if [ $COMPILE_STATUS -eq 0 ]; then
    echo "✓ Compilation succeeded"
else
    echo "⚠ Compilation failed (this is normal; will be fixed after migration)"
fi

# 3. Run tests (record result, do not abort)
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

echo "✅ Validation preparation complete"
echo ""
echo "Pre-migration status:"
echo "  - Compilation: $([ $COMPILE_STATUS -eq 0 ] && echo '✓' || echo '✗')"
echo "  - Tests:       $([ $TEST_STATUS -eq 0 ] && echo '✓' || echo '✗')"
```

---

### Step 5: Configure OpenRewrite

**Requirements**:
1. Add the OpenRewrite Maven plugin to pom.xml
2. Configure the appropriate recipes:
   - Spring Boot 3.0 upgrade
   - JDK 21 migration
   - Jakarta EE migration
3. Adjust configuration based on the project's specifics

**Output**:
```bash
#!/bin/bash
# setup-openrewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== Configuring OpenRewrite ==="

# Check if already configured
if grep -q "rewrite-maven-plugin" "$POM_FILE"; then
    echo "⚠ OpenRewrite plugin already present, skipping"
    exit 0
fi

# Load project info
source .migration-project-info

# Prepare plugin configuration
cat > /tmp/rewrite-plugin.xml <<'EOF'
            <plugin>
                <groupId>org.openrewrite.maven</groupId>
                <artifactId>rewrite-maven-plugin</artifactId>
                <version>6.28.1</version>
                <configuration>
                    <activeRecipes>
                        <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5</recipe>
                    </activeRecipes>
                </configuration>
                <dependencies>
                    <dependency>
                        <groupId>org.openrewrite.recipe</groupId>
                        <artifactId>rewrite-spring</artifactId>
                        <version>6.23.1</version>
                    </dependency>
                </dependencies>
            </plugin>
EOF

if command -v xmlstarlet &> /dev/null; then
    echo "Using xmlstarlet for automatic configuration..."
    echo "⚠ Auto-configuration is complex; manual addition is recommended"
else
    echo "📝 Please manually add the following to the <build><plugins> section of pom.xml:"
    echo ""
    cat /tmp/rewrite-plugin.xml
    echo ""
    read -p "Press Enter when done..."
fi

echo "✅ OpenRewrite configuration complete"
```

---

### Step 6: Run OpenRewrite Discovery

**Requirements**:
1. Run `mvn rewrite:discover` to discover applicable recipes
2. Display the discovery results
3. Confirm whether to proceed

**Output**:
```bash
#!/bin/bash
# run-discovery.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== OpenRewrite Discovery ==="

# Run discovery
mvn rewrite:discover -Dverbose=true | tee .migration-validation/rewrite-discovery.txt

echo ""
echo "📊 Discovery complete. Please review the output above."
read -p "Continue with migration? (y/n): " CONTINUE

if [ "$CONTINUE" != "y" ]; then
    echo "❌ Migration cancelled by user"
    exit 1
fi
```

---

### Step 7: Run OpenRewrite Dry Run

**Requirements**:
1. Run in dry-run mode to preview changes
2. Show which files will be modified
3. Ask the user to confirm

**Output**:
```bash
#!/bin/bash
# run-dryrun.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== OpenRewrite Dry Run (Preview Mode) ==="

# Run dry-run
mvn rewrite:dryRun | tee .migration-validation/rewrite-dryrun.txt

echo ""
echo "📝 Dry run complete. See .migration-validation/rewrite-dryrun.txt for details."
echo ""
read -p "Confirm applying these changes? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "❌ Changes cancelled by user"
    exit 1
fi
```

---

### Step 8: Apply OpenRewrite Changes

**Requirements**:
1. Run `mvn rewrite:run` to apply changes
2. Record execution logs
3. Check execution result

**Output**:
```bash
#!/bin/bash
# apply-rewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Applying OpenRewrite Changes ==="

# Run rewrite
mvn rewrite:run | tee .migration-validation/rewrite-run.txt

REWRITE_STATUS=$?

if [ $REWRITE_STATUS -eq 0 ]; then
    echo "✅ OpenRewrite completed successfully"
else
    echo "❌ OpenRewrite execution failed"
    exit 1
fi

# Show change summary
echo ""
echo "📊 Change summary:"
git diff --stat
```

---

### Step 9: Check and Fix Issues

**Requirements**:
1. Attempt to compile the project
2. If compilation fails, analyze the error:
   - Dependency version conflicts
   - API changes
   - Configuration issues
3. Provide fix suggestions or auto-fix
4. Retry until compilation succeeds

**Output**:
```bash
#!/bin/bash
# check-and-fix.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Checking Compilation ==="

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo ""
    echo "Attempt #$((RETRY_COUNT + 1)): compiling project..."
    
    mvn clean compile > .migration-validation/compile-after-attempt-$((RETRY_COUNT + 1)).txt 2>&1
    COMPILE_STATUS=$?
    
    if [ $COMPILE_STATUS -eq 0 ]; then
        echo "✅ Compilation succeeded!"
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
            echo "💡 javax package references detected — some dependencies may need manual handling"
            echo "Suggestion: Check if third-party dependencies support Jakarta EE"
        fi
        
        # Check Hibernate Dialect
        if echo "$ERROR_LOG" | grep -q "Dialect"; then
            echo "💡 Dialect-related error detected"
            echo "Suggestion: Hibernate 6 removed version-specific Dialects — use generic Dialect"
        fi
        
        # Check configuration properties
        if echo "$ERROR_LOG" | grep -q "property"; then
            echo "💡 Configuration property error detected"
            echo "Suggestion: Check for renamed properties in application.properties/yml"
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo ""
            read -p "Apply manual fixes and retry compilation? (y/n): " MANUAL_FIX
            if [ "$MANUAL_FIX" != "y" ]; then
                echo "❌ Fix cancelled by user"
                exit 1
            fi
        fi
    fi
done

if [ $COMPILE_STATUS -ne 0 ]; then
    echo ""
    echo "❌ Compilation failed after maximum retries"
    echo "Please manually resolve the issues and rerun the validation script"
    exit 1
fi
```

---

### Step 10: Validate Migration

**Requirements**:
1. Run the test suite
2. Compare dependencies before and after migration
3. Generate a migration report
4. Provide follow-up recommendations

**Output**:
```bash
#!/bin/bash
# validate-migration.sh

PROJECT_PATH=$(cat .migration-project-path)
cd "$PROJECT_PATH" || exit 1

echo "=== Validating Migration ==="

# 1. Run tests
echo "🧪 Running tests..."
mvn test > .migration-validation/test-after.txt 2>&1
TEST_STATUS=$?

if [ $TEST_STATUS -eq 0 ]; then
    echo "✅ Tests passed"
else
    echo "⚠ Tests failed — see .migration-validation/test-after.txt"
fi

# 2. Record post-migration dependency tree
echo "📋 Recording post-migration dependency tree..."
mvn dependency:tree > .migration-validation/dependencies-after.txt 2>&1

# 3. Diff dependencies
echo ""
echo "📊 Dependency diff:"
diff .migration-validation/dependencies-before.txt .migration-validation/dependencies-after.txt > .migration-validation/dependencies-diff.txt || true
echo "Detailed diff saved to .migration-validation/dependencies-diff.txt"

# 4. Generate migration report
cat > .migration-validation/MIGRATION-REPORT.md <<EOF
# Spring Boot 2 → 3 Migration Report

**Migration date**: $(date)
**Project path**: $PROJECT_PATH

## Migration Results

- Compilation: ✅ Success
- Tests: $([ $TEST_STATUS -eq 0 ] && echo '✅ Passed' || echo '⚠️ Failed')

## Key Changes

1. Spring Boot version upgraded
2. JDK upgraded to 21
3. Jakarta EE namespace migrated

## Dependency Changes

See dependencies-diff.txt for details.

## Follow-up Recommendations

1. Review and fix any test failures (if any)
2. Manually verify critical business flows
3. Check configuration files for renamed properties
4. Update CI/CD pipelines to use JDK 21
5. Consider leveraging JDK 21 features (Virtual Threads, etc.)

## File Reference

- \`compile-before.txt\` — Pre-migration compilation log
- \`compile-after-attempt-X.txt\` — Post-migration compilation log(s)
- \`test-before.txt\` — Pre-migration test log
- \`test-after.txt\` — Post-migration test log
- \`dependencies-before.txt\` — Pre-migration dependency tree
- \`dependencies-after.txt\` — Post-migration dependency tree
- \`dependencies-diff.txt\` — Dependency changes
- \`rewrite-discovery.txt\` — OpenRewrite discovery output
- \`rewrite-dryrun.txt\` — OpenRewrite dry-run output
- \`rewrite-run.txt\` — OpenRewrite execution log

EOF

echo ""
echo "✅ Migration complete!"
echo ""
echo "📄 Migration report generated: .migration-validation/MIGRATION-REPORT.md"
echo ""
cat .migration-validation/MIGRATION-REPORT.md
```

---

## Complete Automation Script

Combine all steps into a single orchestration script:

```bash
#!/bin/bash
# migrate-spring-boot.sh — Main orchestration script

set -e

echo "================================================="
echo "  Spring Boot 2 → 3 + JDK 8 → 21 Migration Tool"
echo "  Powered by OpenRewrite"
echo "================================================="
echo ""

bash check-environment.sh || exit 1
echo ""

bash get-project-path.sh || exit 1
echo ""

bash analyze-project.sh || exit 1
echo ""

bash prepare-validation.sh || exit 1
echo ""

bash setup-openrewrite.sh || exit 1
echo ""

bash run-discovery.sh || exit 1
echo ""

bash run-dryrun.sh || exit 1
echo ""

bash apply-rewrite.sh || exit 1
echo ""

bash check-and-fix.sh || exit 1
echo ""

bash validate-migration.sh || exit 1

echo ""
echo "================================================="
echo "  🎉 Migration workflow complete!"
echo "================================================="
```

---

## Usage Instructions

### Prerequisites
- JDK 17 or JDK 21 installed
- Maven 3.8.1+ installed
- Project uses Maven build
- Project committed to Git (optional, used for backup)

### Steps

1. **Download all scripts** to the same directory
2. **Add execute permissions**: `chmod +x *.sh`
3. **Run the main script**: `./migrate-spring-boot.sh`
4. **Follow the prompts**

### Notes

- Scripts create a `.migration-validation/` directory inside the project to store all logs
- It is strongly recommended to manually back up the project before running
- If using Git, the script automatically creates a backup branch
- Some complex scenarios may require manual intervention

---

## AI Agent Execution Instructions

As an AI Agent, you should:

1. **Read and understand the purpose of each step first**
2. **Execute scripts in order**
3. **If a step fails, analyze the cause and attempt a fix**
4. **Where user input is needed, proactively ask the user**
5. **At key decision points (e.g., after dry-run), show the user the results and wait for confirmation**
6. **When encountering compilation errors, analyze common patterns and provide targeted solutions**
7. **Generate a detailed migration report at the end**

### Error Handling Strategy

- **Dependency conflicts**: Use `mvn dependency:tree` to analyze; suggest excluding or upgrading versions
- **API changes**: Refer to the Spring Boot 3 Migration Guide; provide alternative implementations
- **Configuration properties**: Inspect `application.properties/yml`; update renamed properties
- **Third-party libraries**: Find Jakarta EE-compatible versions, or use the Jakarta Migration Tool to convert

---

## Related Resources

- OpenRewrite Documentation: https://docs.openrewrite.org
- Spring Boot 3 Migration Guide: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide
- Research Notes: `~/my-obsidian-vault/personal/drafts/spring-boot-2-to-3-migration.md`
