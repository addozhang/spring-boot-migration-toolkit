#!/bin/bash
# setup-openrewrite.sh

PROJECT_PATH=$(cat .migration-project-path)
POM_FILE="$PROJECT_PATH/pom.xml"

echo "=== 配置 OpenRewrite ==="

# 检查是否已配置
if grep -q "rewrite-maven-plugin" "$POM_FILE"; then
    echo "⚠ OpenRewrite 插件已存在，跳过配置"
    exit 0
fi

echo "📝 请手动将以下配置添加到 pom.xml 的 <build><plugins> 中："
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
read -p "添加完成后按回车继续..."

echo "✅ OpenRewrite 配置完成"
