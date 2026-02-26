# Spring Boot Migration Toolkit

🚀 Automated toolkit for migrating Spring Boot 2.x projects to Spring Boot 3.x with JDK 8 to JDK 21 upgrade, powered by OpenRewrite.

## ✨ Features

- ✅ **Highly Automated** — Fully automated migration workflow based on OpenRewrite
- ✅ **Smart Error Handling** — Automatically identifies common issues and provides fix suggestions
- ✅ **Safe Backup Mechanism** — Automatically creates a Git backup branch before migration
- ✅ **Complete Validation Flow** — Before/after state comparison and test verification
- ✅ **Detailed Logging** — All operations recorded to `.migration-validation/` directory
- ✅ **Interactive Confirmation** — Key steps wait for user confirmation

## 📋 What Gets Migrated

- **Spring Boot**: 2.x → 3.5
- **JDK**: 8 → 17 (OpenRewrite default) or 21
- **Jakarta EE**: javax.* → jakarta.*
- **Hibernate**: 5.x → 6.x
- **Spring Framework**: 5.x → 6.x

## 🎯 Applicable Scenarios

✅ Works for:
- Maven-based Java projects
- Spring Boot 2.x applications
- Projects using standard or custom parent POMs

⚠️ Limitations:
- Gradle projects are not yet supported
- Limited support for Kotlin projects

## 🚀 Quick Start

### Prerequisites

- JDK 17 or JDK 21 (required to run OpenRewrite)
- Maven 3.8.1+
- Git (optional, used for automatic backup)

### One-Command Run

```bash
# Clone the repository
git clone https://github.com/addozhang/spring-boot-migration-toolkit.git
cd spring-boot-migration-toolkit

# Add execute permissions
chmod +x scripts/*.sh

# Run migration
./migrate.sh
```

## 📂 Project Structure

```
spring-boot-migration-toolkit/
├── README.md                    # This document (English)
├── README_zh.md                 # Chinese documentation
├── migrate.sh                   # Main orchestration script
├── scripts/                     # Step-by-step scripts
│   ├── 01-check-environment.sh
│   ├── 02-get-project-path.sh
│   ├── 03-analyze-project.sh
│   ├── 04-prepare-validation.sh
│   ├── 05-setup-openrewrite.sh
│   ├── 06-run-discovery.sh
│   ├── 07-run-dryrun.sh
│   ├── 08-apply-rewrite.sh
│   ├── 09-check-and-fix.sh
│   └── 10-validate-migration.sh
├── docs/                        # Detailed documentation
│   ├── PROMPT.md               # AI Agent execution instructions
│   ├── TROUBLESHOOTING.md      # Troubleshooting guide
│   └── RESEARCH.md             # Research reference materials
└── examples/                    # Sample configurations
    └── rewrite-config-example.xml
```

## 📖 Usage Guide

### 1. Environment Check

The script automatically verifies:
- JDK version (requires 17+)
- Maven version
- Project structure

### 2. Project Analysis

Automatically detects:
- Spring Boot version
- Java version
- Parent POM configuration
- Kotlin dependencies (will show warning)

### 3. Migration Flow

1. **Discovery** — Discover applicable OpenRewrite recipes
2. **Dry Run** — Preview changes before applying
3. **Apply** — Apply code transformations
4. **Verify** — Compile and run tests for validation

### 4. Auto-Fix

If compilation fails, the script will:
- Analyze error types (javax/jakarta, Hibernate Dialect, configuration properties, etc.)
- Provide fix suggestions
- Support up to 3 automatic retries

### 5. Generate Report

After migration, the following are generated:
- Migration report (`MIGRATION-REPORT.md`)
- Dependency diff (`dependencies-diff.txt`)
- Full logs (`.migration-validation/` directory)

## 🛠️ Manual Step Execution

To run individual steps:

```bash
# Environment check
./scripts/01-check-environment.sh

# Project analysis
./scripts/03-analyze-project.sh

# Dry-run only
./scripts/07-run-dryrun.sh
```

## 📚 References

- [Spring Boot 3.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)
- [OpenRewrite Documentation](https://docs.openrewrite.org)
- [Spring Boot Migrator](https://github.com/spring-projects-experimental/spring-boot-migrator)
- [Detailed Research Notes](docs/RESEARCH.md)

## 🧪 Test Validation

**Test Project**: [sb2-migration-test](https://github.com/addozhang/sb2-migration-test)

Validated against a comprehensive test project covering 11 migration categories:
- **Automation Rate**: 85–90%
- **Test Pass Rate**: 96% (49/51 non-database tests)
- **Execution Time**: 1 min 12 sec (OpenRewrite)
- **Time Saved**: ~5 hours 40 minutes (OpenRewrite estimate)

Full test report: [MIGRATION_REPORT.md](https://github.com/addozhang/sb2-migration-test/blob/spring-boot-3/MIGRATION_REPORT.md)

## ⚠️ Known Issues Requiring Manual Fix

Although the toolkit is highly automated, the following 2 issues require manual attention:

### 1. Hibernate Dialect Not Updated

**Problem**: OpenRewrite may not update version-specific Hibernate dialects.

**Where to check**: `application.properties` or `application.yml`

**Fix example**:
```properties
# Before (Hibernate 5)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQL10Dialect

# After (Hibernate 6)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
```

Hibernate 6 removed version-specific dialects (e.g., PostgreSQL10Dialect, MySQL57Dialect) — use the generic dialect instead.

### 2. SecurityConfig User Configuration May Be Incomplete

**Problem**: OpenRewrite may drop password and role configuration when converting `InMemoryUserDetailsManager`.

**Detection**:
```bash
grep -A 3 "InMemoryUserDetailsManager" src/main/java/**/SecurityConfig.java | \
  grep -q ".password(" || echo "⚠️ Warning: SecurityConfig may be missing password configuration"
```

**Fix example**:
```java
// ❌ Possible OpenRewrite output (incomplete)
@Bean
InMemoryUserDetailsManager inMemoryAuthManager() {
    return new InMemoryUserDetailsManager(
        User.builder().username("admin").build()  // missing password and roles
    );
}

// ✅ Correct configuration
@Bean
InMemoryUserDetailsManager inMemoryAuthManager() {
    return new InMemoryUserDetailsManager(
        User.builder()
            .username("admin")
            .password(passwordEncoder().encode("admin"))
            .roles("ADMIN", "USER")
            .build()
    );
}
```

Full troubleshooting guide: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 🔧 OpenRewrite Version Requirements

This toolkit uses a tested and verified combination of OpenRewrite versions:

```xml
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <version>6.28.1</version>
    <dependencies>
        <dependency>
            <groupId>org.openrewrite.recipe</groupId>
            <artifactId>rewrite-spring</artifactId>
            <version>6.23.1</version>
        </dependency>
    </dependencies>
</plugin>
```

**Version notes**:
- ✅ **Verified combination** — Fully tested, stable versions
- ✅ **Spring Boot 3.5 support** — Uses `UpgradeSpringBoot_3_5` recipe
- ✅ **Latest versions** — rewrite-maven-plugin 6.28.1 + rewrite-spring 6.23.1
- ℹ️ **rewrite-migrate-java no longer needed** — Already bundled inside rewrite-spring

## ⚠️ Important Notes

1. **Back up your project** — Although the script creates a Git backup branch, an extra backup is recommended
2. **Run the full test suite** — Always validate thoroughly after migration
3. **Third-party dependencies** — Check that all dependencies have Spring Boot 3-compatible versions
4. **Configuration changes** — Manually inspect `application.properties/yml` for renamed properties
5. **CI/CD updates** — Update your build environment to JDK 21

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

MIT License

## 🔗 Related Projects

- [Spring Boot Migrator](https://github.com/spring-projects-experimental/spring-boot-migrator)
- [OpenRewrite](https://github.com/openrewrite)
- [Apache Tomcat Jakarta Migration Tool](https://github.com/apache/tomcat-jakartaee-migration)

---

**Author**: Addo Zhang  
**Repository**: https://github.com/addozhang/spring-boot-migration-toolkit

📖 [中文文档](README_zh.md)
