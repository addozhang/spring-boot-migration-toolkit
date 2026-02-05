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
                <version>5.47.0</version>
                <configuration>
                    <activeRecipes>
                        <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3</recipe>
                        <recipe>org.openrewrite.java.migrate.UpgradeToJava21</recipe>
                        <recipe>org.openrewrite.java.migrate.jakarta.JavaxToJakarta</recipe>
                    </activeRecipes>
                </configuration>
                <dependencies>
                    <dependency>
                        <groupId>org.openrewrite.recipe</groupId>
                        <artifactId>rewrite-spring</artifactId>
                        <version>5.22.0</version>
                    </dependency>
                    <dependency>
                        <groupId>org.openrewrite.recipe</groupId>
                        <artifactId>rewrite-migrate-java</artifactId>
                        <version>2.28.0</version>
                    </dependency>
                </dependencies>
            </plugin>
EOF
echo ""
read -p "Press Enter to continue after adding the configuration..."

echo "✅ OpenRewrite configuration completed"
