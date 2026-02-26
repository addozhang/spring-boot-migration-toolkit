# Troubleshooting Guide

## Common Issues and Solutions

### 1. Environment Issues

#### Issue: JDK version requirement not met

**Error message**:
```
❌ OpenRewrite requires JDK 17+, current version does not meet the requirement
```

**Solution**:
```bash
# Ubuntu/Debian
sudo apt install openjdk-21-jdk

# macOS (using Homebrew)
brew install openjdk@21

# Set JAVA_HOME
export JAVA_HOME=/path/to/jdk-21
export PATH=$JAVA_HOME/bin:$PATH
```

#### Issue: Maven not installed

**Error message**:
```
❌ Maven not detected, please install Maven 3.8.1+
```

**Solution**:
```bash
# Ubuntu/Debian
sudo apt install maven

# macOS
brew install maven

# Verify installation
mvn -v
```

---

### 2. Compilation Errors

#### Issue: javax.* packages not migrated

**Error message**:
```
error: package javax.servlet does not exist
```

**Cause**: Third-party dependencies still use javax.* packages

**Solution**:
1. Check if the dependency has a Jakarta EE compatible version
2. Use the Apache Tomcat Jakarta Migration Tool to convert JAR files
3. Manually update the dependency version

```xml
<!-- Example: update javax.servlet to jakarta.servlet -->
<dependency>
    <groupId>jakarta.servlet</groupId>
    <artifactId>jakarta.servlet-api</artifactId>
    <version>6.0.0</version>
</dependency>
```

#### Issue: Hibernate Dialect not found

**Error message**:
```
error: cannot find symbol PostgreSQL10Dialect
```

**Cause**: Hibernate 6 removed version-specific Dialects

**Solution**:

In `application.properties`:
```properties
# Old configuration (Hibernate 5)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQL10Dialect

# New configuration (Hibernate 6)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
```

Or remove the property entirely and let Hibernate auto-detect the database version.

#### Issue: Configuration property does not exist

**Error message**:
```
Unknown property 'server.max-http-header-size'
```

**Cause**: Property names changed in Spring Boot 3

**Solution**:

```properties
# Spring Boot 2.x
server.max-http-header-size=16KB

# Spring Boot 3.x
server.max-http-request-header-size=16KB
```

Reference: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Configuration-Changelog

#### Issue: SecurityConfig user configuration incomplete (known OpenRewrite issue)

**Error message**:
```
java.lang.IllegalArgumentException: Cannot pass null or empty values to constructor
    at org.springframework.security.core.userdetails.User.<init>
```

**Cause**: OpenRewrite may drop password and role configuration when converting `AuthenticationManagerBuilder` to `InMemoryUserDetailsManager`.

**Before migration** (Spring Boot 2):
```java
@Override
protected void configure(AuthenticationManagerBuilder auth) throws Exception {
    auth.inMemoryAuthentication()
        .withUser("user")
            .password(passwordEncoder().encode("password"))
            .roles("USER")
        .and()
        .withUser("admin")
            .password(passwordEncoder().encode("admin"))
            .roles("ADMIN", "USER");
}
```

**OpenRewrite incorrect output** (Spring Boot 3):
```java
@Bean
InMemoryUserDetailsManager inMemoryAuthManager() throws Exception {
    return new InMemoryUserDetailsManager(
        User.builder().username("admin").build()  // ❌ missing password and roles
    );
}
```

**Correct fix**:
```java
@Bean
InMemoryUserDetailsManager inMemoryAuthManager() throws Exception {
    return new InMemoryUserDetailsManager(
        User.builder()
            .username("user")
            .password(passwordEncoder().encode("password"))
            .roles("USER")
            .build(),
        User.builder()
            .username("admin")
            .password(passwordEncoder().encode("admin"))
            .roles("ADMIN", "USER")
            .build()
    );
}
```

**How to check**:
After migration, search for `InMemoryUserDetailsManager` in `SecurityConfig.java` and ensure every user includes:
- `.username()`
- `.password()` ⚠️ must verify
- `.roles()` or `.authorities()` ⚠️ must verify

**Automated check script**:
```bash
# Check if SecurityConfig is missing password configuration
grep -A 3 "InMemoryUserDetailsManager" src/main/java/**/SecurityConfig.java | \
  grep -q ".password(" || echo "⚠️ Warning: SecurityConfig may be missing password configuration"
```

---

### 3. Dependency Conflicts

#### Issue: Multiple versions of the same dependency

**Error message**:
```
Dependency convergence error for ...
```

**Solution**:

1. View the dependency tree:
```bash
mvn dependency:tree
```

2. Exclude conflicting transitive dependencies:
```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>some-lib</artifactId>
    <version>1.0.0</version>
    <exclusions>
        <exclusion>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

3. Use `dependencyManagement` to enforce a consistent version:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.example</groupId>
            <artifactId>conflicting-lib</artifactId>
            <version>2.0.0</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

---

### 4. Test Failures

#### Issue: @WebMvcTest tests fail

**Error message**:
```
Unable to find a @SpringBootConfiguration
```

**Solution**:

Make sure the test class can locate the `@SpringBootApplication` class:

```java
@WebMvcTest(MyController.class)
@SpringBootTest(classes = MyApplication.class)
public class MyControllerTest {
    // ...
}
```

#### Issue: JPA Repository method not found

**Error message**:
```
The method findById(Long) is undefined for the type MyRepository
```

**Cause**: Hibernate 6 / JPA 3.1 API changes

**Solution**:

Verify the method signature returns the correct type:
```java
// Ensure it returns Optional<T>
Optional<MyEntity> findById(Long id);
```

---

### 5. OpenRewrite Execution Issues

#### Issue: OpenRewrite plugin not taking effect

**Symptom**: `mvn rewrite:discover` throws an error

**Solution**:

1. Confirm plugin configuration is correct:
```bash
mvn help:effective-pom | grep rewrite
```

2. Clear the Maven cache:
```bash
mvn clean
rm -rf ~/.m2/repository/org/openrewrite
mvn rewrite:discover
```

#### Issue: Recipe not found

**Error message**:
```
Could not find recipe 'org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3'
```

**Solution**:

Verify that the dependency version matches:
```xml
<dependency>
    <groupId>org.openrewrite.recipe</groupId>
    <artifactId>rewrite-spring</artifactId>
    <version>6.7.0</version> <!-- ensure this is up to date -->
</dependency>
```

List available recipes:
```bash
mvn rewrite:discover
```

---

### 6. Custom Parent POM Issues

#### Issue: Parent POM conflict

**Symptom**: Spring Boot version cannot be upgraded

**Solution 1**: Update the Parent POM

If your organization maintains a custom parent POM, upgrade it to one that supports Spring Boot 3 first.

**Solution 2**: Replace with BOM import

```xml
<!-- Remove parent -->
<!-- <parent>...</parent> -->

<!-- Use dependencyManagement to import the BOM -->
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

<!-- Manually add plugins previously provided by the parent -->
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

---

### 7. Database-Related Issues

#### Issue: Driver version incompatibility

**Error message**:
```
java.sql.SQLException: No suitable driver found
```

**Solution**:

Update database drivers to compatible versions:

```xml
<!-- PostgreSQL -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.7.0</version>
</dependency>

<!-- MySQL -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <version>8.2.0</version>
</dependency>
```

#### Issue: Flyway migration failure

**Cause**: Flyway version needs to be upgraded for Spring Boot 3 compatibility

**Solution**:

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
    <version>9.22.0</version>
</dependency>
```

---

### 8. Performance Issues

#### Issue: Longer startup time

**Cause**: Changes in Spring Boot 3 + Hibernate 6 initialization logic

**Optimization tips**:

1. Enable virtual threads (JDK 21):
```properties
spring.threads.virtual.enabled=true
```

2. Tune Hibernate configuration:
```properties
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
```

3. Narrow component scan scope:
```java
@SpringBootApplication(scanBasePackages = "com.example.specific")
```

---

## Debugging Tips

### View Detailed Logs

```bash
# OpenRewrite verbose logs
mvn rewrite:run -X

# Inspect dependency conflicts
mvn dependency:tree -Dverbose

# View effective POM
mvn help:effective-pom > effective-pom.xml
```

### Incremental Migration

If full automatic migration fails, apply recipes one by one:

```bash
# Upgrade Spring Boot only
mvn rewrite:run -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0

# Migrate Java version only
mvn rewrite:run -Drewrite.activeRecipes=org.openrewrite.java.migrate.UpgradeToJava17

# Migrate Jakarta namespace only
mvn rewrite:run -Drewrite.activeRecipes=org.openrewrite.java.migrate.jakarta.JavaxToJakarta
```

---

## Getting Help

- **OpenRewrite Community**: https://github.com/openrewrite/rewrite/discussions
- **Spring Boot Issues**: https://github.com/spring-projects/spring-boot/issues
- **Stack Overflow**: tags `spring-boot-3` + `migration`

---

If you encounter issues not covered in this guide, please:
1. Check the full logs in the `.migration-validation/` directory
2. Search GitHub Issues and Stack Overflow
3. Open an Issue in this repository with detailed logs attached
