# Spring Boot 2 → 3 迁移工具指南

> 基于 [openrewrite-migration-demo](https://github.com/addozhang/openrewrite-migration-demo) 项目的实战经验总结。  
> 目标：让任意 Spring Boot 2.x 项目能以最低人工成本升级到 Spring Boot 3.x。

---

## 目录

1. [整体思路](#整体思路)
2. [前置条件](#前置条件)
3. [Step 1：运行官方迁移 Recipe](#step-1运行官方迁移-recipe)
4. [Step 2：处理自动迁移未覆盖的问题](#step-2处理自动迁移未覆盖的问题)
5. [Step 3：自定义 Recipe（可复用）](#step-3自定义-recipe可复用)
6. [已验证的迁移案例清单](#已验证的迁移案例清单)
7. [常见错误排查](#常见错误排查)
8. [迁移后验证 Checklist](#迁移后验证-checklist)
9. [项目结构参考](#项目结构参考)

---

## 整体思路

```
SB2 项目
   │
   ├─ Step 1: mvn rewrite:run (UpgradeSpringBoot_3_5)   ← 自动处理 80%
   │
   ├─ Step 2: 手动修复剩余编译错误                        ← 处理 ~15%
   │
   ├─ Step 3: 自定义 Recipe（内部 API 迁移）               ← 可沉淀复用
   │
   └─ 验证：compile → test → 运行时 API 测试
```

**核心原则**：所有变更尽量用 OpenRewrite Recipe 驱动，不手动改代码。这样：
- 变更有记录、可审计
- 同样的问题在其他项目可以一键批量修复
- Recipe 本身就是迁移知识的载体

---

## 前置条件

| 要求 | 说明 |
|------|------|
| Java | JDK 17+（SB3 最低要求） |
| Maven | 3.6.3+ |
| 项目 | 已在 SB2 下能正常 `mvn compile` |

---

## Step 1：运行官方迁移 Recipe

### 一键命令

```bash
mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5
```

**多模块项目**只对指定模块运行：

```bash
mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5 \
  -pl web-app
```

### 这一步自动处理的内容

| 类别 | 变更 |
|------|------|
| **namespace** | `javax.*` → `jakarta.*`（persistence、validation、servlet 等） |
| **Spring Security** | `WebSecurityConfigurerAdapter` → `SecurityFilterChain` Bean |
| **Spring MVC** | `WebMvcConfigurerAdapter` → 实现 `WebMvcConfigurer` 接口 |
| **拦截器** | `HandlerInterceptorAdapter` → 实现 `HandlerInterceptor` 接口 |
| **异步配置** | `AsyncConfigurerSupport` → 实现 `AsyncConfigurer` 接口 |
| **JUnit** | `@RunWith(SpringRunner.class)` → `@ExtendWith(SpringExtension.class)` |
| **JUnit** | `org.junit.Test` → `org.junit.jupiter.api.Test` |
| **JUnit** | `org.junit.Assert.*` → `org.junit.jupiter.api.Assertions.*` |
| **HTTP 客户端** | `org.apache.http`（HttpClient 4）→ `org.apache.hc.client5`（HttpClient 5）|
| **异常处理** | `ResponseEntityExceptionHandler` 方法签名 `HttpStatus` → `HttpStatusCode` |
| **ResponseStatusException** | `.getStatus()` → `.getStatusCode()` |
| **MediaType** | `APPLICATION_JSON_UTF8_VALUE` → `APPLICATION_JSON_VALUE` |
| **Properties** | SB2 特有 key 自动重命名（如 `spring.datasource.initialization-mode`）|
| **pom.xml** | Spring Boot parent 版本升级、移除过时依赖（JUnit 4）|

---

## Step 2：处理自动迁移未覆盖的问题

### 2.1 Apache HttpComponents 版本冲突

**现象**：
```
java.lang.NoSuchMethodError: 'void org.apache.hc.core5.http.impl.io.DefaultHttpRequestWriterFactory.<init>(Http1Config)'
```

**根因**：  
OpenRewrite 将 `httpclient` 升级到 `httpclient5 5.4.x`，但 `httpcore5` 未随之升级，版本不匹配。

| 组件 | 错误版本 | 正确版本 |
|------|---------|---------|
| `httpclient5` | 5.4.4 | 5.4.4 |
| `httpcore5` | 5.2.5 ❌ | 5.3.4 ✅ |

**解决方案（用 Recipe，不要手动改）**：  
参考 [Step 3](#step-3自定义-recipe可复用) 中的 `FixHttpComponents5VersionMismatch` recipe。

### 2.2 `@Bean` 方法返回 `void`

**现象**：SB3 不允许 `@Bean` 方法返回 `void`，编译报错。

**解决**：将返回类型改为具体类型或 `Object`。

```java
// SB2（错误）
@Bean
public void initializeDefaults() { ... }

// SB3（正确）
@Bean
public Object initializeDefaults() {
    // ...
    return null;
}
```

### 2.3 `HttpComponentsClientHttpRequestFactory` deprecated setters

**现象**：`setReadTimeout(int)` 在 HttpClient 5 中被移除，只有警告注释，不会自动重写。

**解决**：手动迁移到 `RequestConfig`：

```java
// HttpClient 5 写法
RequestConfig requestConfig = RequestConfig.custom()
    .setResponseTimeout(Timeout.ofSeconds(30))
    .setConnectTimeout(Timeout.ofSeconds(5))
    .setConnectionRequestTimeout(Timeout.ofSeconds(10))
    .build();
CloseableHttpClient httpClient = HttpClients.custom()
    .setDefaultRequestConfig(requestConfig)
    .build();
```

### 2.4 `Hibernate Dialect` 警告

**现象**：
```
HHH90000025: H2Dialect does not need to be specified explicitly
```

**解决**：从 `application.properties` 移除：
```properties
# 删除此行
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect
```

---

## Step 3：自定义 Recipe（可复用）

在多项目/团队场景下，将内部 API 迁移和依赖修复封装成自定义 Recipe，一次编写，多处复用。

### 项目结构

```
your-project/
├── pom.xml                      ← 配置 rewrite-maven-plugin
├── migration-recipes/
│   ├── pom.xml
│   └── src/main/resources/
│       └── META-INF/rewrite/
│           └── migration.yml    ← Recipe 定义
└── app/
    └── pom.xml
```

### 根 pom.xml 配置

```xml
<build>
  <pluginManagement>
    <plugins>
      <plugin>
        <groupId>org.openrewrite.maven</groupId>
        <artifactId>rewrite-maven-plugin</artifactId>
        <version>6.12.0</version>
        <configuration>
          <exportDatatables>true</exportDatatables>
          <activeRecipes>
            <recipe>com.yourcompany.recipes.FixHttpComponents5VersionMismatch</recipe>
            <recipe>com.yourcompany.recipes.MigrateInternalLibV2</recipe>
          </activeRecipes>
        </configuration>
        <dependencies>
          <!-- 引入本地自定义 recipes jar -->
          <dependency>
            <groupId>com.yourcompany</groupId>
            <artifactId>migration-recipes</artifactId>
            <version>${project.version}</version>
          </dependency>
        </dependencies>
      </plugin>
    </plugins>
  </pluginManagement>
</build>
```

### Recipe 模板：修复依赖版本

```yaml
---
type: specs.openrewrite.org/v1beta/recipe
name: com.yourcompany.recipes.FixHttpComponents5VersionMismatch
displayName: Fix Apache HttpComponents 5 version mismatch
description: >
  Aligns httpcore5 version with httpclient5 5.4.x.
  httpclient5 5.4.x requires httpcore5 5.3.x.
recipeList:
  - org.openrewrite.maven.ChangePropertyValue:
      key: httpcore5.version
      newValue: 5.3.4
      addIfMissing: true
```

### Recipe 模板：迁移内部公共库 API

当团队内部公共库（common-lib）升级并改变了 API 时，编写 Recipe 代替人工搜索替换：

```yaml
---
type: specs.openrewrite.org/v1beta/recipe
name: com.yourcompany.recipes.MigrateInternalLibV2
displayName: Migrate internal common-lib v1 → v2
description: Migrates deprecated v1 APIs to v2 equivalents.
recipeList:
  # 方法重命名（先改方法名，再改类名）
  - org.openrewrite.java.ChangeMethodName:
      methodPattern: com.example.common.response.ApiResponse success(..)
      newMethodName: ok
  - org.openrewrite.java.ChangeMethodName:
      methodPattern: com.example.common.response.ApiResponse fail(..)
      newMethodName: error
  # 类型迁移
  - org.openrewrite.java.ChangeType:
      oldFullyQualifiedTypeName: com.example.common.response.ApiResponse
      newFullyQualifiedTypeName: com.example.common.response.ApiResult
  # 注解迁移
  - org.openrewrite.java.ChangeType:
      oldFullyQualifiedTypeName: com.example.common.annotation.RequireLogin
      newFullyQualifiedTypeName: com.example.common.annotation.Authenticated
```

### 执行自定义 Recipe

```bash
# 先 install recipes jar 到本地 repo
mvn install -pl migration-recipes -q

# 运行 recipe
mvn org.openrewrite.maven:rewrite-maven-plugin:6.12.0:run -pl app
```

---

## 已验证的迁移案例清单

以下所有案例均已在 `openrewrite-migration-demo` 项目中通过端到端验证。

### 自动迁移（OpenRewrite 全自动）

| # | 场景 | SB2 写法 | SB3 写法 | Recipe |
|---|------|---------|---------|--------|
| 1 | JPA 命名空间 | `javax.persistence.*` | `jakarta.persistence.*` | `UpgradeSpringBoot_3_5` |
| 2 | Validation 命名空间 | `javax.validation.*` | `jakarta.validation.*` | `UpgradeSpringBoot_3_5` |
| 3 | Servlet 命名空间 | `javax.servlet.*` | `jakarta.servlet.*` | `UpgradeSpringBoot_3_5` |
| 4 | Spring Security 配置 | `extends WebSecurityConfigurerAdapter` | `@Bean SecurityFilterChain` | `UpgradeSpringBoot_3_5` |
| 5 | MVC 配置 | `extends WebMvcConfigurerAdapter` | `implements WebMvcConfigurer` | `UpgradeSpringBoot_3_5` |
| 6 | 拦截器 | `extends HandlerInterceptorAdapter` | `implements HandlerInterceptor` | `UpgradeSpringBoot_3_5` |
| 7 | 异步配置 | `extends AsyncConfigurerSupport` | `implements AsyncConfigurer` | `UpgradeSpringBoot_3_5` |
| 8 | JUnit 4 → 5 | `@RunWith(SpringRunner.class)` | `@ExtendWith(SpringExtension.class)` | `UpgradeSpringBoot_3_5` |
| 9 | JUnit 断言 | `org.junit.Assert.*` | `org.junit.jupiter.api.Assertions.*` | `UpgradeSpringBoot_3_5` |
| 10 | HTTP 客户端 | `org.apache.http.impl.client.*` | `org.apache.hc.client5.http.impl.classic.*` | `UpgradeSpringBoot_3_5` |
| 11 | 异常处理签名 | `HttpStatus status` | `HttpStatusCode status` | `UpgradeSpringBoot_3_5` |
| 12 | 异常状态码 | `.getStatus().value()` | `.getStatusCode().value()` | `UpgradeSpringBoot_3_5` |
| 13 | MediaType 常量 | `APPLICATION_JSON_UTF8_VALUE` | `APPLICATION_JSON_VALUE` | `UpgradeSpringBoot_3_5` |
| 14 | Properties key | `spring.datasource.initialization-mode` | `spring.sql.init.mode` | `UpgradeSpringBoot_3_5` |

### 半自动迁移（Recipe + 自定义）

| # | 场景 | 处理方式 |
|---|------|---------|
| 15 | httpcore5/httpclient5 版本对齐 | 自定义 `FixHttpComponents5VersionMismatch` Recipe |
| 16 | 内部公共库 API 迁移 | 自定义 `MigrateInternalLibV2` Recipe |

### 需要手动处理

| # | 场景 | 原因 | 处理方式 |
|---|------|------|---------|
| 17 | `setReadTimeout` 被移除 | HttpClient 5 API 行为变化，无法自动推断意图 | 手动改为 `RequestConfig` + `Timeout` |
| 18 | `@Bean` 返回 `void` | SB3 编译错误，语义变更 | 手动改返回类型 |
| 19 | Hibernate H2Dialect 显式配置 | 仅 Warning，不影响运行，但应清理 | 从 `application.properties` 删除 |

---

## 常见错误排查

### `NoSuchMethodError` in HttpComponents

```
java.lang.NoSuchMethodError: 'void org.apache.hc.core5.http.impl.io.DefaultHttpRequestWriterFactory.<init>(...)'
```

→ httpcore5 与 httpclient5 版本不兼容。运行 `FixHttpComponents5VersionMismatch` recipe，或在 `pom.xml` 中手动添加：
```xml
<httpcore5.version>5.3.4</httpcore5.version>
```

### `Failed to load ApplicationContext`

编译通过但 Spring Context 无法启动。常见原因：
- `@Bean` 方法返回 `void`
- Security 配置未正确迁移
- 依赖版本冲突

→ 看 `caused by` 链的最后一条，定位根本原因。

### `BeanCreationException` on RestTemplate

→ 检查 HttpClient 依赖版本，参考 [2.1 节](#21-apache-httpcomponents-版本冲突)。

---

## 迁移后验证 Checklist

```bash
# 1. 全量编译（含测试代码）
mvn clean compile test-compile

# 2. 单元测试
mvn test

# 3. 全量构建（含 install）
mvn clean install

# 4. 运行时验证
mvn spring-boot:run -pl <module>
curl http://localhost:8080/actuator/health
# → {"status":"UP"}

# 5. 关键接口冒烟测试
curl http://localhost:8080/api/users
curl -X POST http://localhost:8080/api/users -H "Content-Type: application/json" -d '{...}'

# 6. 确认依赖版本
mvn dependency:tree -pl <module> | grep httpcore5
# → httpcore5:jar:5.3.4（与 httpclient5 匹配）
```

---

## 项目结构参考

`openrewrite-migration-demo` 是本指南的配套 Demo 项目，涵盖了上表中所有迁移场景：

```
openrewrite-migration-demo/
├── pom.xml                          # Root: Spring Boot 3.5.0, rewrite-maven-plugin
├── common-lib/                      # 内部公共库（演示内部 API 迁移）
│   └── src/main/java/com/example/common/
│       ├── response/ApiResult.java  # v2: ApiResponse → ApiResult
│       ├── annotation/Authenticated.java  # v2: @RequireLogin → @Authenticated
│       └── util/StringUtil.java
├── web-app/                         # 主应用（包含所有迁移案例）
│   ├── pom.xml
│   └── src/main/java/com/example/demo/
│       ├── config/
│       │   ├── SecurityConfig.java        # SB3 SecurityFilterChain
│       │   ├── WebConfig.java             # implements WebMvcConfigurer
│       │   ├── AsyncConfig.java           # implements AsyncConfigurer
│       │   └── RestTemplateConfig.java    # HttpClient 5
│       ├── controller/UserController.java
│       ├── exception/
│       │   ├── GlobalExceptionHandler.java # HttpStatusCode
│       │   └── UserNotFoundException.java
│       ├── interceptor/LoggingInterceptor.java  # implements HandlerInterceptor
│       ├── model/User.java                # jakarta.persistence
│       └── actuator/CustomHealthIndicator.java
└── migration-recipes/               # 自定义可复用 Recipe
    └── src/main/resources/META-INF/rewrite/
        └── common-lib-migration.yml
```

### Git 标签说明

| 标签 | 说明 |
|------|------|
| `744d7e7` | SB2 初始版本 |
| `43f34c9` | SB2 扩展版（含更多迁移案例） |
| `sb2-with-common-lib` | SB2 + 内部公共库 |
| `sb2-round4` | SB2 Round 4（HttpClient4、异常处理等） |
| `master (HEAD)` | SB3 迁移完成 + httpcore5 修复 |

---

## 快速命令速查

```bash
# 一键运行官方迁移（单模块）
mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5 \
  -pl <module-name>

# 运行自定义 Recipe
mvn install -pl migration-recipes -q
mvn org.openrewrite.maven:rewrite-maven-plugin:6.12.0:run -pl <module-name>

# 查看 Recipe 修改了哪些文件
git diff --stat

# 还原 Recipe 改动（如需重新执行）
git checkout <module>/pom.xml <module>/src/

# 验证依赖树
mvn dependency:tree -pl <module> | grep -E "httpclient5|httpcore5|spring-boot"
```

---

*文档生成时间：2026-02-28 | 基于 openrewrite-migration-demo 实战验证*
