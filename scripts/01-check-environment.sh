#!/bin/bash
# check-environment.sh

echo "=== Environment Check ==="

# Check Java version
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    echo "✓ Java version: $JAVA_VERSION"
    if [ "$JAVA_VERSION" -lt 17 ]; then
        echo "❌ OpenRewrite requires JDK 17+, current version does not meet requirement"
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
