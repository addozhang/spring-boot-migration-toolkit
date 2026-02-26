# Research Materials: Spring Boot 2 → 3.5.10 + JDK 8 → 21 Upgrade Guide

**Created**: 2026-02-04  
**Last Updated**: 2026-02-04  
**Status**: Collecting  
**Related Blog**: (pending)

---

## 🎯 Upgrade Overview

### Key Changes
- **Spring Boot**: 2.x → 3.5.10
- **JDK**: 8 → 21
- **Jakarta EE**: javax.* → jakarta.* (namespace change)
- **Spring Framework**: 5.x → 6.x
- **Minimum JDK**: JDK 17 (Spring Boot 3.0+)

### Architecture Scenarios
1. Projects directly using Spring Boot parent POM
2. Projects managing versions via a custom parent POM
3. Projects mixing in internal company libraries

---

## 🛠️ Automated Migration Tools

### 1. Spring Boot Migrator (SBM) ⭐ Officially Recommended

**Repository**: https://github.com/spring-projects-experimental/spring-boot-migrator

**Support**:
- ✅ Java projects
- ✅ Maven builds
- ✅ Spring Boot 2.7 → 3.0 automated upgrade
- ❌ Kotlin (not supported)
- ❌ Gradle (not supported)

**Usage**:
```bash
# Download latest release
wget https://github.com/spring-projects-experimental/spring-boot-migrator/releases/latest/download/spring-boot-upgrade.jar

# Run migration (requires JDK 17)
java -jar --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
     --add-opens java.base/java.io=ALL-UNNAMED \
     spring-boot-upgrade.jar <path-to-application>
```

**Key Features**:
- Interactive Web UI
- Automated code refactoring
- Powered by the OpenRewrite engine
- Generates migration reports

**Demo Video**: https://www.youtube.com/embed/RKXblzn8lFg (2 min 26 sec)

**Current Status**: 🚧 Undergoing official rework and improvements
- Reference: https://github.com/spring-projects-experimental/spring-boot-migrator/discussions/859

---

### 2. OpenRewrite ⭐⭐⭐ Highly Recommended

**Official Site**: https://docs.openrewrite.org  
**GitHub**: https://github.com/openrewrite

OpenRewrite is a powerful automated code refactoring framework. Spring Boot Migrator also uses it under the hood.

#### Core Projects

| Project | Stars | Description | GitHub |
|---------|-------|-------------|--------|
| rewrite-spring | 369⭐ | Spring project migration recipes | https://github.com/openrewrite/rewrite-spring |
| rewrite-maven-plugin | 173⭐ | Maven plugin | https://github.com/openrewrite/rewrite-maven-plugin |
| rewrite-migrate-java | 145⭐ | Java version migration | https://github.com/openrewrite/rewrite-migrate-java |
| rewrite-testing-frameworks | 90⭐ | Test framework migration | https://github.com/openrewrite/rewrite-testing-frameworks |

#### Maven Usage

Add the plugin to your project's `pom.xml`:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.openrewrite.maven</groupId>
            <artifactId>rewrite-maven-plugin</artifactId>
            <version>5.x.x</version>
            <configuration>
                <activeRecipes>
                    <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0</recipe>
                    <recipe>org.openrewrite.java.migrate.UpgradeToJava21</recipe>
                </activeRecipes>
            </configuration>
            <dependencies>
                <dependency>
                    <groupId>org.openrewrite.recipe</groupId>
                    <artifactId>rewrite-spring</artifactId>
                    <version>5.x.x</version>
                </dependency>
                <dependency>
                    <groupId>org.openrewrite.recipe</groupId>
                    <artifactId>rewrite-migrate-java</artifactId>
                    <version>2.x.x</version>
                </dependency>
            </dependencies>
        </plugin>
    </plugins>
</build>
```

Run migration:
```bash
# Discover applicable recipes
mvn rewrite:discover

# Dry-run (preview only)
mvn rewrite:dryRun

# Apply migration
mvn rewrite:run
```

#### Key Recipes

**Spring Boot 3 Upgrade**:
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0`
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_1`
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2`
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3`

**JDK Upgrade**:
- `org.openrewrite.java.migrate.UpgradeToJava17`
- `org.openrewrite.java.migrate.UpgradeToJava21`

**Jakarta EE Migration**:
- `org.openrewrite.java.migrate.jakarta.JavaxToJakarta`

#### Advantages
- ✅ Precise refactoring at the syntax tree level
- ✅ Supports Maven and Gradle
- ✅ Customizable recipes
- ✅ Active community with continuously updated recipes
- ✅ Recipes are composable

**Reference Project**:
- Example: https://github.com/dashaun/openrewrite-spring-boot-upgrade-example (12⭐)

---

### 3. Jakarta EE Migration Tools

#### Apache Tomcat Jakarta Migration Tool

**GitHub**: https://github.com/apache/tomcat-jakartaee-migration (181⭐)

**Purpose**: Handles javax.* → jakarta.* namespace migration

```bash
# Convert JAR/WAR files
java -jar jakartaee-migration-1.0.x-shaded.jar <source> <destination>

# Convert source code directory
java -jar jakartaee-migration-1.0.x-shaded.jar <source-dir> <dest-dir> --source
```

**Use Cases**:
- Handle third-party dependencies that cannot be automatically migrated
- Convert compiled JAR/WAR archives
- Batch-convert source code directories

#### Gradle Jakarta Migration Plugin

**GitHub**: https://github.com/nebula-plugins/gradle-jakartaee-migration-plugin (53⭐)

**Purpose**: Jakarta EE migration for Gradle projects

```groovy
plugins {
    id 'nebula.jakartaee-migration' version 'x.x.x'
}
```

---

## 🤖 AI-Assisted Tools

### 1. Spring Boot 3 Migration Analyzer

**GitHub**: https://github.com/nilabja-banerjee/estimation_calculator

**Description**: AI-driven code analysis and effort estimation tool

**Features**:
- Scans project source code
- Estimates migration effort
- Generates migration reports

**Last Updated**: 2026-01-31

---

### 2. Jakarta Migration MCP

**GitHub**: https://github.com/adrianmikula/JakartaMigrationMCP (1⭐)

**Last Updated**: 2026-02-04 (very new!)

**Description**: MCP (Model Context Protocol) server for AI-assisted migration

**Note**: Project is new; stability needs further evaluation

---

## ⚠️ Critical Migration Considerations

### 1. JDK Upgrade

#### JDK 8 → 21 Major Changes

**New Features**:
- ✨ Virtual Threads — JDK 21 GA
- ✨ Records — JDK 16
- ✨ Sealed Classes — JDK 17
- ✨ Pattern Matching enhancements — JDK 21
- ✨ Switch Expressions — JDK 14

**Removed Features**:
- ❌ Nashorn JavaScript engine (deprecated JDK 11, removed JDK 15)
- ❌ Some legacy SecurityManager APIs
- ❌ RMI Activation (JDK 17)

**Reference**:
- Stack Overflow: "What exactly makes Java Virtual Threads better" (45 votes)
  - https://stackoverflow.com/questions/72116652/what-exactly-makes-java-virtual-threads-better

**Recommendations**:
1. Upgrade to JDK 17 first (minimum for Spring Boot 3)
2. After tests pass, upgrade to JDK 21
3. Use OpenRewrite to automatically handle syntax upgrades

---

### 2. Jakarta EE Namespace Change

**Core Change**: `javax.*` → `jakarta.*`

Affected packages:
```
javax.servlet.*      → jakarta.servlet.*
javax.persistence.*  → jakarta.persistence.*
javax.validation.*   → jakarta.validation.*
javax.mail.*         → jakarta.mail.*
javax.xml.ws.*       → jakarta.xml.ws.*
javax.xml.bind.*     → jakarta.xml.bind.*
javax.annotation.*   → jakarta.annotation.*
```

**Common Issues**:

1. **Third-party library incompatibility**
   - Problem: Dependency library still uses javax.* packages
   - Solution: Use the Jakarta Migration Tool to convert JAR files

2. **SOAP Web Services**
   - SO: "Spring Boot 3 Update: No qualifying bean of type 'jakarta.xml.ws.WebServiceContext'" (5 votes)
   - https://stackoverflow.com/questions/75928808/spring-boot-3-update-no-qualifying-bean-of-type-jakarta-xml-ws-webserviceconte
   
3. **Mail configuration migration**
   - SO: "Javax mail configuration migration to jakarta mail" (2 votes)
   - https://stackoverflow.com/questions/74566373/javax-mail-configuration-migration-to-jakarta-mail

---

### 3. Hibernate 6 Changes

Spring Boot 3 uses Hibernate 6, which includes significant breaking changes:

**Dialect Configuration Changes**:
- SO: "What happened to PostgreSQL10Dialect in Hibernate 6.x?" (22 votes)
  - https://stackoverflow.com/questions/74744188/what-happened-to-postgresql10dialect-in-hibernate-6-x
  - Solution: Use the generic Dialect — Hibernate 6 auto-detects the database version

**JPA Repository Method Changes**:
- SO: "The method findById is undefined for the type after migrating to Boot 3" (13 votes)
  - https://stackoverflow.com/questions/74900974/the-method-findbyid-is-undefined-for-the-type-after-migrating-to-boot-3

---

### 4. Spring Boot Configuration Changes

**Renamed Properties**:
```properties
# Spring Boot 2.x
server.max-http-header-size=16KB

# Spring Boot 3.x
server.max-http-request-header-size=16KB
```

- SO: "how to set maxHttpHeaderSize in spring-boot 3.x" (12 votes)
  - https://stackoverflow.com/questions/75460562/how-to-set-maxhttpheadersize-in-spring-boot-3-x

**Auto-configuration Changes**:
- Some auto-configuration class paths have changed
- Certain starter dependencies may need to be added explicitly

---

### 5. Test Framework Adjustments

**Spring Boot Test Changes**:
- SO: "Does @WebMvcTest require @SpringBootApplication annotation?" (13 votes)
  - https://stackoverflow.com/questions/38890944/does-webmvctest-require-springbootapplication-annotation

**Recommendation**:
- Use `rewrite-testing-frameworks` recipes to automatically handle test code migration

---

### 6. Custom Parent POM Strategy

For projects using a custom parent POM:

**Option 1: Update the Parent POM**
```xml
<parent>
    <groupId>com.company</groupId>
    <artifactId>company-parent</artifactId>
    <version>2.0.0</version> <!-- new version based on Spring Boot 3 -->
</parent>
```

**Option 2: Use BOM (Bill of Materials)**
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>3.5.10</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <!-- Internal company dependency BOM -->
        <dependency>
            <groupId>com.company</groupId>
            <artifactId>company-dependencies</artifactId>
            <version>2.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

**Advantages**:
- Decouples Spring Boot version from internal dependencies
- More flexible version management
- Reduces parent POM conflicts

---

### 7. Internal Library Compatibility

**Checklist**:

1. ✅ Does the internal lib support JDK 17+?
2. ✅ Does it use javax.* packages (migration required)?
3. ✅ Does it depend on Spring Boot 2-specific APIs?
4. ✅ Does it have custom auto-configuration (needs updating for Spring Boot 3)?

**Migration Strategy**:
- Publish a Jakarta-compatible version of internal libs first
- Use semantic versioning (e.g., 2.0.0 → 3.0.0)
- Provide dual-version support during the transition period

---

### 8. Database Drivers and Connection Pools

**Driver Version Requirements**:
- PostgreSQL: 42.5.1+
- MySQL: 8.0.31+
- Oracle: 21.x+

**HikariCP**:
- Spring Boot 3 defaults to HikariCP 5.x
- Some configuration properties may have changed

---

### 9. Monitoring and Logging

**Micrometer Tracing**:
- Spring Boot 3 introduces a new tracing abstraction
- SO: "Spring Boot 3 TaskExecutor context propagation in micrometer tracing" (14 votes)
  - https://stackoverflow.com/questions/75401265/spring-boot-3-taskexecutor-context-propagation-in-micrometer-tracing

**Logging Frameworks**:
- Ensure Log4j2/Logback versions are compatible with JDK 21
- Review any custom Appender implementations

---

## 📝 Recommended Upgrade Process

### Phase 1: Preparation (1–2 weeks)

1. **Environment setup**
   - Install JDK 17 and JDK 21
   - Create a dedicated migration branch
   - Set up a CI/CD test environment

2. **Dependency audit**
   - List all direct dependencies
   - Check third-party library Spring Boot 3 compatibility
   - Assess internal library compatibility

3. **Tool preparation**
   - Download Spring Boot Migrator
   - Configure the OpenRewrite Maven plugin
   - Prepare the Jakarta Migration Tool

### Phase 2: Automated Migration (1 week)

1. **Run OpenRewrite**
   ```bash
   mvn rewrite:run -DactiveRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0
   ```

2. **Resolve compilation errors**
   - Fix code changes not covered by automatic migration
   - Handle API changes

3. **Update dependency versions**
   - Upgrade all dependencies to compatible versions
   - Resolve dependency conflicts

### Phase 3: Testing and Validation (2–3 weeks)

1. **Unit tests**
   - Run all unit tests
   - Fix test failures

2. **Integration tests**
   - Validate database integration
   - Validate external service calls
   - Validate caches, message queues, etc.

3. **Performance tests**
   - Compare performance before and after migration
   - Optionally optimize using Virtual Threads

4. **Compatibility tests**
   - Verify compatibility with other services
   - Verify API contracts are preserved

### Phase 4: Canary Release (1–2 weeks)

1. Small-traffic canary rollout
2. Monitor key metrics
3. Gradually increase traffic
4. Full rollout

---

## 🔗 Official Documentation

### Spring Boot Official

- **Spring Boot 3.0 Release Notes**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Release-Notes
- **Spring Boot 3.5 Docs**: https://docs.spring.io/spring-boot/index.html
- **Migration Guide**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide

### OpenRewrite Official

- **Documentation**: https://docs.openrewrite.org
- **Recipe Catalog**: https://docs.openrewrite.org/recipes
- **Maven Plugin**: https://docs.openrewrite.org/reference/rewrite-maven-plugin

### Jakarta EE Official

- **Jakarta EE Specifications**: https://jakarta.ee/specifications/
- **Namespace Migration Guide**: https://blogs.oracle.com/javamagazine/post/transition-from-java-ee-to-jakarta-ee

---

## 📊 Material Summary

- Official tools: 3 (SBM, OpenRewrite, Jakarta Migration)
- AI tools: 2
- GitHub repositories: 15+
- Stack Overflow questions: 20+
- Key consideration categories: 9

---

## 🎯 Pending Additions

- [ ] New features and changes in Spring Boot 3.1–3.5
- [ ] Virtual Threads real-world usage examples
- [ ] Performance comparison data (Spring Boot 2 vs 3)
- [ ] Real-world enterprise migration case studies
- [ ] Common gotchas and solutions summary
- [ ] Guide to writing custom OpenRewrite recipes

---

**Last Updated**: 2026-02-04 23:00 UTC
