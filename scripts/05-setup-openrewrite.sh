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

echo "📝 Please manually add the following configuration to <build><plugins> in pom.xml:"
echo ""
cat <<'EOF'
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
echo ""
read -p "Press Enter to continue after adding the configuration..."

echo "✅ OpenRewrite configuration completed"
