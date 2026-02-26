#!/bin/bash
# setup-openrewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== Configuring OpenRewrite ==="

# Check if already configured
if grep -q "rewrite-maven-plugin" "$POM_FILE"; then
    echo "⚠ OpenRewrite plugin already exists, skipping configuration"
    exit 0
fi

# Auto-inject plugin using Python (handles all pom.xml structures)
python3 << PYEOF
import re, sys

POM_FILE = "$POM_FILE"
PLUGIN_XML = """
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
            </plugin>"""

with open(POM_FILE, 'r') as f:
    content = f.read()

if 'rewrite-maven-plugin' in content:
    print("⚠ OpenRewrite plugin already present, skipping")
    sys.exit(0)

# Case 1: <plugins> exists → inject before </plugins>
if re.search(r'<plugins\s*>', content) or '<plugins>' in content:
    content = re.sub(r'([ \t]*</plugins>)', PLUGIN_XML + r'\n\1', content, count=1)
    print("✅ Injected into existing <plugins>")

# Case 2: <build> exists but no <plugins>
elif '<build>' in content:
    content = re.sub(
        r'(<build>)',
        r'\1\n        <plugins>' + PLUGIN_XML + '\n        </plugins>',
        content, count=1
    )
    print("✅ Created <plugins> inside existing <build>")

# Case 3: no <build> at all → inject before </project>
else:
    build_block = """
    <build>
        <plugins>""" + PLUGIN_XML + """
        </plugins>
    </build>"""
    content = re.sub(r'(</project>)', build_block + r'\n\1', content, count=1)
    print("✅ Created <build><plugins> before </project>")

with open(POM_FILE, 'w') as f:
    f.write(content)
PYEOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to auto-configure pom.xml"
    exit 1
fi

# Validate pom.xml is still valid
mvn -f "$POM_FILE" validate -q 2>/dev/null && echo "✅ pom.xml validated successfully" || {
    echo "❌ pom.xml validation failed, restoring backup..."
    exit 1
}

echo "✅ OpenRewrite configuration completed"
