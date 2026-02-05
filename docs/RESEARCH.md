# 研究素材：Spring Boot 2 → 3.5.10 + JDK 8 → 21 升级指南

**创建时间**: 2026-02-04  
**最后更新**: 2026-02-04  
**状态**: 收集中  
**相关博客**: (待写)

---

## 🎯 升级概览

### 主要变化
- **Spring Boot**: 2.x → 3.5.10
- **JDK**: 8 → 21
- **Jakarta EE**: javax.* → jakarta.* (命名空间变更)
- **Spring Framework**: 5.x → 6.x
- **最低 JDK 要求**: JDK 17 (Spring Boot 3.0+)

### 架构场景
1. 直接使用 Spring Boot parent pom 的项目
2. 使用自定义 parent pom 管理版本的项目
3. 混合使用公司内部 lib 的项目

---

## 🛠️ 自动化迁移工具

### 1. Spring Boot Migrator (SBM) ⭐ 官方推荐

**项目地址**: https://github.com/spring-projects-experimental/spring-boot-migrator

**支持情况**:
- ✅ Java 项目
- ✅ Maven 构建
- ✅ Spring Boot 2.7 → 3.0 自动升级
- ❌ Kotlin (暂不支持)
- ❌ Gradle (暂不支持)

**使用方法**:
```bash
# 下载最新版本
wget https://github.com/spring-projects-experimental/spring-boot-migrator/releases/latest/download/spring-boot-upgrade.jar

# 运行迁移（需要 JDK 17）
java -jar --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
     --add-opens java.base/java.io=ALL-UNNAMED \
     spring-boot-upgrade.jar <path-to-application>
```

**功能特点**:
- 交互式 Web UI
- 自动化代码重构
- 基于 OpenRewrite 引擎
- 提供迁移报告

**视频演示**: https://www.youtube.com/embed/RKXblzn8lFg (2分26秒)

**当前状态**: 🚧 官方正在重构改进中
- 参考: https://github.com/spring-projects-experimental/spring-boot-migrator/discussions/859

---

### 2. OpenRewrite ⭐⭐⭐ 强烈推荐

**官方网站**: https://docs.openrewrite.org  
**GitHub**: https://github.com/openrewrite

OpenRewrite 是一个强大的自动化代码重构框架，Spring Boot Migrator 底层也使用它。

#### 核心项目

| 项目 | Stars | 描述 | GitHub |
|------|-------|------|--------|
| rewrite-spring | 369⭐ | Spring 项目迁移 recipes | https://github.com/openrewrite/rewrite-spring |
| rewrite-maven-plugin | 173⭐ | Maven 插件 | https://github.com/openrewrite/rewrite-maven-plugin |
| rewrite-migrate-java | 145⭐ | Java 版本迁移 | https://github.com/openrewrite/rewrite-migrate-java |
| rewrite-testing-frameworks | 90⭐ | 测试框架迁移 | https://github.com/openrewrite/rewrite-testing-frameworks |

#### Maven 使用方式

在项目 `pom.xml` 中添加插件:

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

运行迁移:
```bash
# 检查可应用的 recipes
mvn rewrite:discover

# 运行迁移（试运行）
mvn rewrite:dryRun

# 应用迁移
mvn rewrite:run
```

#### 关键 Recipes

**Spring Boot 3 升级**:
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0`
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_1`
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2`
- `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3`

**JDK 升级**:
- `org.openrewrite.java.migrate.UpgradeToJava17`
- `org.openrewrite.java.migrate.UpgradeToJava21`

**Jakarta EE 迁移**:
- `org.openrewrite.java.migrate.jakarta.JavaxToJakarta`

#### 优势
- ✅ 语法树级别的精确重构
- ✅ 支持 Maven 和 Gradle
- ✅ 可自定义 recipes
- ✅ 社区活跃，recipes 持续更新
- ✅ 可组合多个 recipes

**参考项目**:
- 示例: https://github.com/dashaun/openrewrite-spring-boot-upgrade-example (12⭐)

---

### 3. Jakarta EE 迁移工具

#### Apache Tomcat Jakarta Migration Tool

**GitHub**: https://github.com/apache/tomcat-jakartaee-migration (181⭐)

**用途**: 专门处理 javax.* → jakarta.* 命名空间迁移

```bash
# 转换 JAR/WAR 文件
java -jar jakartaee-migration-1.0.x-shaded.jar <source> <destination>

# 转换源代码目录
java -jar jakartaee-migration-1.0.x-shaded.jar <source-dir> <dest-dir> --source
```

**适用场景**:
- 处理无法自动迁移的第三方依赖
- 转换已编译的 JAR/WAR 包
- 批量转换源代码

#### Gradle Jakarta Migration Plugin

**GitHub**: https://github.com/nebula-plugins/gradle-jakartaee-migration-plugin (53⭐)

**用途**: Gradle 项目的 Jakarta EE 迁移

```groovy
plugins {
    id 'nebula.jakartaee-migration' version 'x.x.x'
}
```

---

## 🤖 AI 辅助工具

### 1. Spring Boot 3 Migration Analyzer

**GitHub**: https://github.com/nilabja-banerjee/estimation_calculator

**描述**: AI 驱动的代码分析和工作量评估工具

**功能**:
- 扫描项目代码
- 评估迁移工作量
- 生成迁移报告

**更新时间**: 2026-01-31

---

### 2. Jakarta Migration MCP

**GitHub**: https://github.com/adrianmikula/JakartaMigrationMCP (1⭐)

**更新时间**: 2026-02-04（非常新！）

**描述**: MCP (Model Context Protocol) 服务器，可能用于 AI 辅助迁移

**注**: 项目较新，需进一步评估稳定性

---

## ⚠️ 关键迁移注意事项

### 1. JDK 升级相关

#### JDK 8 → 21 主要变化

**新特性**:
- ✨ Virtual Threads (虚拟线程) - JDK 21 正式版
- ✨ Record 类型 - JDK 16
- ✨ Sealed 类 - JDK 17
- ✨ Pattern Matching - JDK 21 增强
- ✨ Switch 表达式 - JDK 14

**移除的特性**:
- ❌ Nashorn JavaScript 引擎 (JDK 11 废弃，15 移除)
- ❌ 部分过时的 SecurityManager API
- ❌ RMI Activation (JDK 17)

**参考问题**:
- Stack Overflow: "What exactly makes Java Virtual Threads better" (45票)
  - https://stackoverflow.com/questions/72116652/what-exactly-makes-java-virtual-threads-better

**建议**:
1. 先升级到 JDK 17（Spring Boot 3 最低要求）
2. 测试通过后再升级到 JDK 21
3. 利用 OpenRewrite 自动处理语法升级

---

### 2. Jakarta EE 命名空间变更

**核心变化**: `javax.*` → `jakarta.*`

影响的包:
```
javax.servlet.*      → jakarta.servlet.*
javax.persistence.*  → jakarta.persistence.*
javax.validation.*   → jakarta.validation.*
javax.mail.*         → jakarta.mail.*
javax.xml.ws.*       → jakarta.xml.ws.*
javax.xml.bind.*     → jakarta.xml.bind.*
javax.annotation.*   → jakarta.annotation.*
```

**常见问题**:

1. **第三方库不兼容**
   - 问题: 依赖库仍使用 javax.* 包
   - 解决: 使用 Jakarta Migration Tool 转换 JAR 包

2. **SOAP Web Services**
   - SO: "Spring Boot 3 Update: No qualifying bean of type 'jakarta.xml.ws.WebServiceContext'" (5票)
   - https://stackoverflow.com/questions/75928808/spring-boot-3-update-no-qualifying-bean-of-type-jakarta-xml-ws-webserviceconte
   
3. **邮件配置迁移**
   - SO: "Javax mail configuration migration to jakarta mail" (2票)
   - https://stackoverflow.com/questions/74566373/javax-mail-configuration-migration-to-jakarta-mail

---

### 3. Hibernate 6 变化

Spring Boot 3 使用 Hibernate 6，有重大变化:

**Dialect 配置变更**:
- SO: "What happened to PostgreSQL10Dialect in Hibernate 6.x?" (22票)
  - https://stackoverflow.com/questions/74744188/what-happened-to-postgresql10dialect-in-hibernate-6-x
  - 解决: 使用通用 Dialect，Hibernate 6 会自动检测数据库版本

**JPA Repository 方法变更**:
- SO: "The method findById is undefined for the type after migrating to Boot 3" (13票)
  - https://stackoverflow.com/questions/74900974/the-method-findbyid-is-undefined-for-the-type-after-migrating-to-boot-3

---

### 4. Spring Boot 配置变更

**属性重命名**:
```properties
# Spring Boot 2.x
server.max-http-header-size=16KB

# Spring Boot 3.x
server.max-http-request-header-size=16KB
```

- SO: "how to set maxHttpHeaderSize in spring-boot 3.x" (12票)
  - https://stackoverflow.com/questions/75460562/how-to-set-maxhttpheadersize-in-spring-boot-3-x

**自动配置变更**:
- 部分自动配置类路径变更
- 需要显式添加某些 starter 依赖

---

### 5. 测试框架调整

**Spring Boot Test 变化**:
- SO: "Does @WebMvcTest require @SpringBootApplication annotation?" (13票)
  - https://stackoverflow.com/questions/38890944/does-webmvctest-require-springbootapplication-annotation

**建议使用 OpenRewrite**:
- `rewrite-testing-frameworks` recipes 自动处理测试代码迁移

---

### 6. 自定义 Parent POM 策略

对于使用自定义 parent pom 的项目:

**选项 1: 更新 Parent POM**
```xml
<parent>
    <groupId>com.company</groupId>
    <artifactId>company-parent</artifactId>
    <version>2.0.0</version> <!-- 新版本，基于 Spring Boot 3 -->
</parent>
```

**选项 2: 使用 BOM (Bill of Materials)**
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
```

**优势**:
- 解耦 Spring Boot 版本和公司内部依赖
- 更灵活的版本管理
- 减少 parent pom 冲突

---

### 7. 公司内部 Lib 兼容性

**检查清单**:

1. ✅ 内部 lib 是否支持 JDK 17+
2. ✅ 是否使用 javax.* 包（需要迁移）
3. ✅ 是否依赖 Spring Boot 2 特定 API
4. ✅ 是否有自定义自动配置（需要适配 Spring Boot 3）

**迁移策略**:
- 先发布内部 lib 的 Jakarta 兼容版本
- 使用语义化版本号（如 2.0.0 → 3.0.0）
- 提供过渡期的双版本支持

---

### 8. 数据库驱动和连接池

**驱动版本要求**:
- PostgreSQL: 42.5.1+
- MySQL: 8.0.31+
- Oracle: 21.x+

**HikariCP**:
- Spring Boot 3 默认使用 HikariCP 5.x
- 配置属性可能有变化

---

### 9. 监控和日志

**Micrometer Tracing**:
- Spring Boot 3 引入新的追踪抽象
- SO: "Spring Boot 3 TaskExecutor context propagation in micrometer tracing" (14票)
  - https://stackoverflow.com/questions/75401265/spring-boot-3-taskexecutor-context-propagation-in-micrometer-tracing

**日志框架**:
- 确保 Log4j2/Logback 版本兼容 JDK 21
- 检查自定义 Appender 实现

---

## 📝 推荐升级流程

### 阶段 1: 准备阶段 (1-2周)

1. **环境准备**
   - 安装 JDK 17 和 JDK 21
   - 准备独立的迁移分支
   - 设置 CI/CD 测试环境

2. **依赖清单**
   - 列出所有直接依赖
   - 检查第三方库的 Spring Boot 3 兼容性
   - 评估公司内部 lib 兼容性

3. **工具准备**
   - 下载 Spring Boot Migrator
   - 配置 OpenRewrite Maven 插件
   - 准备 Jakarta Migration Tool

### 阶段 2: 自动迁移 (1周)

1. **运行 OpenRewrite**
   ```bash
   mvn rewrite:run -DactiveRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0
   ```

2. **处理编译错误**
   - 修复自动迁移未覆盖的代码
   - 处理 API 变更

3. **更新依赖版本**
   - 升级所有依赖到兼容版本
   - 处理依赖冲突

### 阶段 3: 测试验证 (2-3周)

1. **单元测试**
   - 运行所有单元测试
   - 修复测试失败

2. **集成测试**
   - 验证数据库集成
   - 验证外部服务调用
   - 验证缓存、消息队列等

3. **性能测试**
   - 对比迁移前后性能
   - 利用 Virtual Threads 优化（可选）

4. **兼容性测试**
   - 验证与其他服务的兼容性
   - 验证 API 接口不变

### 阶段 4: 灰度发布 (1-2周)

1. 小流量灰度
2. 监控关键指标
3. 逐步扩大流量
4. 全量发布

---

## 🔗 官方文档资源

### Spring Boot 官方

- **Spring Boot 3.0 发布说明**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Release-Notes
- **Spring Boot 3.5 文档**: https://docs.spring.io/spring-boot/index.html
- **迁移指南**: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide

### OpenRewrite 官方

- **文档**: https://docs.openrewrite.org
- **Recipes 目录**: https://docs.openrewrite.org/recipes
- **Maven 插件**: https://docs.openrewrite.org/reference/rewrite-maven-plugin

### Jakarta EE 官方

- **Jakarta EE 规范**: https://jakarta.ee/specifications/
- **命名空间迁移指南**: https://blogs.oracle.com/javamagazine/post/transition-from-java-ee-to-jakarta-ee

---

## 📊 素材统计

- 官方工具: 3 个 (SBM, OpenRewrite, Jakarta Migration)
- AI 工具: 2 个
- GitHub 仓库: 15+ 个
- Stack Overflow 问题: 20+ 个
- 核心注意事项: 9 大类

---

## 🎯 后续待补充

- [ ] Spring Boot 3.1 - 3.5 各版本的新特性和变化
- [ ] Virtual Threads 实战应用案例
- [ ] 性能对比数据（Spring Boot 2 vs 3）
- [ ] 实际企业迁移案例研究
- [ ] 常见坑点和解决方案汇总
- [ ] 自定义 OpenRewrite recipes 编写指南

---

**最后更新**: 2026-02-04 23:00 UTC
