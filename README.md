# Spring Boot Migration Toolkit

🚀 自动化工具集，用于将 Spring Boot 2.x 项目迁移到 Spring Boot 3.x，同时升级 JDK 8 到 JDK 21。

## ✨ 特性

- ✅ **自动化程度高** - 基于 OpenRewrite 的完全自动化迁移流程
- ✅ **智能错误处理** - 自动识别常见问题并提供修复建议
- ✅ **安全备份机制** - 自动创建 Git 备份分支
- ✅ **完整验证流程** - 迁移前后状态对比和测试验证
- ✅ **详细日志记录** - 所有操作记录到 `.migration-validation/` 目录
- ✅ **交互式确认** - 关键步骤等待用户确认

## 📋 迁移内容

- **Spring Boot**: 2.x → 3.5.x
- **JDK**: 8 → 21
- **Jakarta EE**: javax.* → jakarta.*
- **Hibernate**: 5.x → 6.x
- **Spring Framework**: 5.x → 6.x

## 🎯 适用场景

✅ 适用于：
- Maven 构建的 Java 项目
- Spring Boot 2.x 应用
- 使用标准或自定义 parent POM

⚠️ 限制：
- 暂不支持 Gradle 项目
- 对 Kotlin 项目支持有限

## 🚀 快速开始

### 前置要求

- JDK 17 或 JDK 21 (OpenRewrite 运行环境)
- Maven 3.8.1+
- Git (可选，用于自动备份)

### 一键运行

```bash
# 克隆仓库
git clone https://github.com/addozhang/spring-boot-migration-toolkit.git
cd spring-boot-migration-toolkit

# 添加执行权限
chmod +x scripts/*.sh

# 运行迁移
./migrate.sh
```

## 📂 项目结构

```
spring-boot-migration-toolkit/
├── README.md                    # 项目说明
├── migrate.sh                   # 主控脚本
├── scripts/                     # 各步骤脚本
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
├── docs/                        # 详细文档
│   ├── PROMPT.md               # AI Agent 执行指令
│   ├── TROUBLESHOOTING.md      # 故障排查指南
│   └── RESEARCH.md             # 研究资料汇总
└── examples/                    # 示例配置
    └── rewrite-config-example.xml
```

## 📖 使用指南

### 1. 环境检查

脚本会自动检查：
- JDK 版本（需要 17+）
- Maven 版本
- 项目结构

### 2. 项目分析

自动识别：
- Spring Boot 版本
- Java 版本
- Parent POM 配置
- Kotlin 依赖（会提示警告）

### 3. 迁移流程

1. **Discovery** - 发现可应用的 OpenRewrite recipes
2. **Dry Run** - 预览变更内容
3. **Apply** - 应用代码变更
4. **Verify** - 编译和测试验证

### 4. 自动修复

如果编译失败，脚本会：
- 分析错误类型（javax/jakarta、Hibernate Dialect、配置属性等）
- 提供修复建议
- 支持最多 3 次重试

### 5. 生成报告

迁移完成后生成：
- 迁移报告 (`MIGRATION-REPORT.md`)
- 依赖对比 (`dependencies-diff.txt`)
- 完整日志（`.migration-validation/` 目录）

## 🛠️ 手动使用

如果需要单独执行某个步骤：

```bash
# 环境检查
./scripts/01-check-environment.sh

# 项目分析
./scripts/03-analyze-project.sh

# 只运行 dry-run
./scripts/07-run-dryrun.sh
```

## 📚 参考资源

- [Spring Boot 3.0 迁移指南](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)
- [OpenRewrite 文档](https://docs.openrewrite.org)
- [Spring Boot Migrator](https://github.com/spring-projects-experimental/spring-boot-migrator)
- [详细研究资料](docs/RESEARCH.md)

## 🧪 测试验证

**测试项目**: [sb2-migration-test](https://github.com/addozhang/sb2-migration-test)

在一个覆盖 11 个迁移类别的综合测试项目中验证：
- **自动化程度**: 85-90%
- **测试通过率**: 96% (49/51 非数据库测试)
- **执行时间**: 1分12秒 (OpenRewrite)
- **节省时间**: 约 5小时40分钟 (OpenRewrite 估算)

查看完整测试报告：[MIGRATION_REPORT.md](https://github.com/addozhang/sb2-migration-test/blob/spring-boot-3/MIGRATION_REPORT.md)

## ⚠️ 已知问题和手动修复

虽然工具自动化程度很高，但以下 2 个问题需要手动检查：

### 1. Hibernate 方言未更新

**问题**: OpenRewrite 可能不会更新版本特定的 Hibernate 方言。

**检查位置**: `application.properties` 或 `application.yml`

**修复示例**:
```properties
# 修复前 (Hibernate 5)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQL10Dialect

# 修复后 (Hibernate 6)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
```

Hibernate 6 移除了版本特定的方言（如 PostgreSQL10Dialect、MySQL57Dialect），统一使用通用方言。

### 2. SecurityConfig 用户配置可能不完整

**问题**: OpenRewrite 在转换 `InMemoryUserDetailsManager` 时可能会丢失密码和角色配置。

**检查方法**:
```bash
# 自动检测
grep -A 3 "InMemoryUserDetailsManager" src/main/java/**/SecurityConfig.java | \
  grep -q ".password(" || echo "⚠️ 警告：SecurityConfig 可能缺少密码配置"
```

**修复示例**:
```java
// ❌ OpenRewrite 可能的输出（不完整）
@Bean
InMemoryUserDetailsManager inMemoryAuthManager() {
    return new InMemoryUserDetailsManager(
        User.builder().username("admin").build()  // 缺少密码和角色
    );
}

// ✅ 正确的配置
@Bean
InMemoryUserDetailsManager inMemoryAuthManager() {
    return new InMemoryUserDetailsManager(
        User.builder()
            .username("admin")
            .password(passwordEncoder().encode("admin"))  // 必须包含
            .roles("ADMIN", "USER")                       // 必须包含
            .build()
    );
}
```

详细故障排查指南：[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 🔧 OpenRewrite 版本要求

本工具使用经过验证的 OpenRewrite 版本组合：

```xml
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <version>6.4.0</version>
    <dependencies>
        <dependency>
            <groupId>org.openrewrite.recipe</groupId>
            <artifactId>rewrite-spring</artifactId>
            <version>6.4.0</version>
        </dependency>
        <dependency>
            <groupId>org.openrewrite.recipe</groupId>
            <artifactId>rewrite-migrate-java</artifactId>
            <version>2.20.0</version>
        </dependency>
    </dependencies>
</plugin>
```

**版本说明**：
- ✅ **已验证组合** - 经过完整测试的稳定版本
- ✅ **版本对齐** - plugin、spring、migrate-java 版本需配套使用
- ⚠️ **不建议升级** - 更高版本（如 6.7.0+）存在已知兼容性问题

## ⚠️ 注意事项

1. **备份项目** - 虽然脚本会创建 Git 备份分支，建议额外备份
2. **测试完整性** - 迁移后务必运行完整的测试套件
3. **第三方依赖** - 检查所有依赖是否有 Spring Boot 3 兼容版本
4. **配置变更** - 手动检查 `application.properties/yml` 的属性变更
5. **CI/CD 更新** - 更新构建环境到 JDK 21

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🔗 相关项目

- [Spring Boot Migrator](https://github.com/spring-projects-experimental/spring-boot-migrator)
- [OpenRewrite](https://github.com/openrewrite)
- [Apache Tomcat Jakarta Migration Tool](https://github.com/apache/tomcat-jakartaee-migration)

---

**作者**: Addo Zhang  
**仓库**: https://github.com/addozhang/spring-boot-migration-toolkit
