# 故障排查指南

## 常见问题及解决方案

### 1. 环境问题

#### 问题：JDK 版本不满足要求

**错误信息**:
```
❌ OpenRewrite 需要 JDK 17+，当前版本不满足
```

**解决方案**:
```bash
# Ubuntu/Debian
sudo apt install openjdk-21-jdk

# macOS (使用 Homebrew)
brew install openjdk@21

# 设置 JAVA_HOME
export JAVA_HOME=/path/to/jdk-21
export PATH=$JAVA_HOME/bin:$PATH
```

#### 问题：Maven 未安装

**错误信息**:
```
❌ 未检测到 Maven，请安装 Maven 3.8.1+
```

**解决方案**:
```bash
# Ubuntu/Debian
sudo apt install maven

# macOS
brew install maven

# 验证安装
mvn -v
```

---

### 2. 编译错误

#### 问题：javax.* 包未迁移

**错误信息**:
```
error: package javax.servlet does not exist
```

**原因**: 第三方依赖仍使用 javax.* 包

**解决方案**:
1. 检查依赖是否有 Jakarta EE 兼容版本
2. 使用 Apache Tomcat Jakarta Migration Tool 转换 JAR 包
3. 手动更新依赖版本

```xml
<!-- 示例：更新 javax.servlet 到 jakarta.servlet -->
<dependency>
    <groupId>jakarta.servlet</groupId>
    <artifactId>jakarta.servlet-api</artifactId>
    <version>6.0.0</version>
</dependency>
```

#### 问题：Hibernate Dialect 不存在

**错误信息**:
```
error: cannot find symbol PostgreSQL10Dialect
```

**原因**: Hibernate 6 移除了版本特定的 Dialect

**解决方案**:

在 `application.properties` 中:
```properties
# 旧配置 (Hibernate 5)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQL10Dialect

# 新配置 (Hibernate 6)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
```

或者完全移除该配置，让 Hibernate 自动检测。

#### 问题：配置属性不存在

**错误信息**:
```
Unknown property 'server.max-http-header-size'
```

**原因**: Spring Boot 3 中属性名称变更

**解决方案**:

```properties
# Spring Boot 2.x
server.max-http-header-size=16KB

# Spring Boot 3.x
server.max-http-request-header-size=16KB
```

参考: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Configuration-Changelog

---

### 3. 依赖冲突

#### 问题：多个版本的同一依赖

**错误信息**:
```
Dependency convergence error for ...
```

**解决方案**:

1. 查看依赖树:
```bash
mvn dependency:tree
```

2. 排除冲突的传递依赖:
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

3. 使用 `dependencyManagement` 统一版本:
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

### 4. 测试失败

#### 问题：@WebMvcTest 相关测试失败

**错误信息**:
```
Unable to find a @SpringBootConfiguration
```

**解决方案**:

确保测试类能找到 `@SpringBootApplication` 类:

```java
@WebMvcTest(MyController.class)
@SpringBootTest(classes = MyApplication.class)
public class MyControllerTest {
    // ...
}
```

#### 问题：JPA Repository 方法不存在

**错误信息**:
```
The method findById(Long) is undefined for the type MyRepository
```

**原因**: Hibernate 6 / JPA 3.1 API 变更

**解决方案**:

检查方法签名是否正确:
```java
// 确保返回 Optional<T>
Optional<MyEntity> findById(Long id);
```

---

### 5. OpenRewrite 执行问题

#### 问题：OpenRewrite 插件未生效

**症状**: `mvn rewrite:discover` 报错

**解决方案**:

1. 确认插件配置正确:
```bash
mvn help:effective-pom | grep rewrite
```

2. 清理 Maven 缓存:
```bash
mvn clean
rm -rf ~/.m2/repository/org/openrewrite
mvn rewrite:discover
```

#### 问题：Recipe 未找到

**错误信息**:
```
Could not find recipe 'org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3'
```

**解决方案**:

检查依赖版本是否匹配:
```xml
<dependency>
    <groupId>org.openrewrite.recipe</groupId>
    <artifactId>rewrite-spring</artifactId>
    <version>5.22.0</version> <!-- 确保版本最新 -->
</dependency>
```

更新到最新版本:
```bash
# 查看可用 recipes
mvn rewrite:discover
```

---

### 6. 自定义 Parent POM 问题

#### 问题：Parent POM 冲突

**症状**: Spring Boot 版本无法升级

**解决方案 1**: 更新 Parent POM

如果公司有维护的 Parent POM，请先升级它到支持 Spring Boot 3。

**解决方案 2**: 使用 BOM 替代

```xml
<!-- 移除 parent -->
<!-- <parent>...</parent> -->

<!-- 使用 dependencyManagement 导入 BOM -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>3.5.10</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <!-- 公司内部依赖 BOM -->
        <dependency>
            <groupId>com.company</groupId>
            <artifactId>company-dependencies</artifactId>
            <version>2.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<!-- 需要手动添加之前 parent 提供的插件 -->
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

### 7. 数据库相关问题

#### 问题：驱动版本不兼容

**错误信息**:
```
java.sql.SQLException: No suitable driver found
```

**解决方案**:

更新数据库驱动到兼容版本:

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

#### 问题：Flyway 迁移失败

**原因**: Flyway 版本需要升级以支持 Spring Boot 3

**解决方案**:

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
    <version>9.22.0</version>
</dependency>
```

---

### 8. 性能问题

#### 问题：启动时间变长

**原因**: Spring Boot 3 + Hibernate 6 初始化逻辑变化

**优化建议**:

1. 启用虚拟线程 (JDK 21):
```properties
spring.threads.virtual.enabled=true
```

2. 调整 Hibernate 配置:
```properties
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
```

3. 优化组件扫描:
```java
@SpringBootApplication(scanBasePackages = "com.example.specific")
```

---

## 调试技巧

### 查看详细日志

```bash
# OpenRewrite 详细日志
mvn rewrite:run -X

# 查看依赖冲突
mvn dependency:tree -Dverbose

# 检查有效的 POM
mvn help:effective-pom > effective-pom.xml
```

### 逐步迁移

如果自动迁移失败，可以逐个应用 recipe:

```bash
# 只升级 Spring Boot
mvn rewrite:run -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0

# 只迁移 Java 版本
mvn rewrite:run -Drewrite.activeRecipes=org.openrewrite.java.migrate.UpgradeToJava17

# 只迁移 Jakarta
mvn rewrite:run -Drewrite.activeRecipes=org.openrewrite.java.migrate.jakarta.JavaxToJakarta
```

---

## 获取帮助

- **OpenRewrite 社区**: https://github.com/openrewrite/rewrite/discussions
- **Spring Boot Issues**: https://github.com/spring-projects/spring-boot/issues
- **Stack Overflow**: 标签 `spring-boot-3` + `migration`

---

如果遇到本指南未覆盖的问题，请：
1. 检查 `.migration-validation/` 目录中的完整日志
2. 搜索 GitHub Issues 和 Stack Overflow
3. 在项目仓库提 Issue 并附上详细日志
