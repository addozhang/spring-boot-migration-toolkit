# Spring Boot 2 → 3 Migration Toolkit (v2)

> OpenRewrite-driven toolkit for migrating Spring Boot 2.x projects to Spring Boot 3.x.  
> This v2 branch contains the recipe-first approach — all migrations are driven by OpenRewrite recipes, not manual edits.

## What's Inside

| Path | Description |
|------|-------------|
| `migration-recipes/` | Maven module with reusable custom OpenRewrite recipes |
| `SPRING_BOOT_2_TO_3_MIGRATION_GUIDE.md` | End-to-end migration guide (19 verified cases) |

## Quick Start

### 1. Run the official Spring Boot 3 upgrade recipe

```bash
mvn -U org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5
```

### 2. Fix known post-migration issues with custom recipes

```bash
# Build recipes jar
mvn install -pl migration-recipes -q

# Run custom fix recipes (e.g., httpcore5 version alignment)
mvn org.openrewrite.maven:rewrite-maven-plugin:6.12.0:run -pl <your-module>
```

### 3. Verify

```bash
mvn clean install
curl http://localhost:8080/actuator/health
```

## Custom Recipes

Located in `migration-recipes/src/main/resources/META-INF/rewrite/`:

| Recipe | Purpose |
|--------|---------|
| `FixHttpComponents5VersionMismatch` | Aligns `httpcore5` version with `httpclient5 5.4.x` |
| `MigrateCommonLibV2` | Template: migrate internal library API (method/type/annotation rename) |

## Full Guide

See [SPRING_BOOT_2_TO_3_MIGRATION_GUIDE.md](./SPRING_BOOT_2_TO_3_MIGRATION_GUIDE.md) for:
- 19 verified migration cases (auto / semi-auto / manual)
- Common error troubleshooting
- Post-migration verification checklist

## Demo Project

See [spring-boot-migration-demo](https://github.com/addozhang/sb2-migration-test) — `sb2-v2` (before) vs `sb3-v2` (after).
