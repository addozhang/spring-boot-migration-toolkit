#!/bin/bash
# analyze-project.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== Analyzing Project ==="

# Detect Spring Boot version via effective-pom (handles multi-level parent inheritance,
# custom parent POMs, and BOM imports without downloading any jar dependencies)
echo "🔍 Resolving Spring Boot version (resolving parent chain)..."
EFFECTIVE_POM=$(mvn -f "$POM_FILE" help:effective-pom 2>/dev/null)

# Method 1: spring-boot-dependencies BOM in dependencyManagement
SPRING_BOOT_VERSION=$(echo "$EFFECTIVE_POM" | \
  grep -A2 'spring-boot-dependencies' | \
  grep '<version>' | sed -E 's/.*<version>([^<]+)<.*/\1/' | head -1)

# Method 2: spring-boot.version property (direct spring-boot-starter-parent descendants)
if [ -z "$SPRING_BOOT_VERSION" ]; then
  SPRING_BOOT_VERSION=$(echo "$EFFECTIVE_POM" | \
    grep '<spring-boot.version>' | \
    sed -E 's/.*<spring-boot.version>([^<]+)<.*/\1/' | head -1)
fi

# Method 3: spring-boot-starter-parent version in parent block
if [ -z "$SPRING_BOOT_VERSION" ]; then
  SPRING_BOOT_VERSION=$(echo "$EFFECTIVE_POM" | \
    grep -A3 'spring-boot-starter-parent' | \
    grep '<version>' | sed -E 's/.*<version>([^<]+)<.*/\1/' | head -1)
fi

# Method 4: fallback — spring-boot artifact version in dependencyManagement
if [ -z "$SPRING_BOOT_VERSION" ]; then
  SPRING_BOOT_VERSION=$(echo "$EFFECTIVE_POM" | \
    grep -B1 '<artifactId>spring-boot</artifactId>' | \
    grep '<version>' | sed -E 's/.*<version>([^<]+)<.*/\1/' | head -1)
fi

echo "Spring Boot Version: ${SPRING_BOOT_VERSION:-Not detected}"

# Extract Java version (macOS compatible)
JAVA_VERSION=$(grep '<java.version>' "$POM_FILE" | sed -E 's/.*<java.version>([^<]+)<.*/\1/' || \
               grep '<maven.compiler.source>' "$POM_FILE" | sed -E 's/.*<maven.compiler.source>([^<]+)<.*/\1/')
echo "Java Version: ${JAVA_VERSION:-Not detected}"

# Check for parent POM
HAS_PARENT=$(grep -c "<parent>" "$POM_FILE")
if [ "$HAS_PARENT" -gt 0 ]; then
    PARENT_ARTIFACT=$(grep -A 3 "<parent>" "$POM_FILE" | grep '<artifactId>' | head -n 1 | sed -E 's/.*<artifactId>([^<]+)<.*/\1/')
    echo "Using Parent POM: $PARENT_ARTIFACT"
fi

# Check for Kotlin project
if grep -q "kotlin-maven-plugin" "$POM_FILE"; then
    echo "❌ Kotlin project detected. OpenRewrite has limited Kotlin support."
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

echo "✅ Project information saved"
