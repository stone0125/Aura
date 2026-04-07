---
name: check-layers
description: Verify Aura's dependency layering rules have not been violated across all Dart files
---

# Check Dependency Layers

Scan all Dart files in `lib/` for dependency layering violations as defined in CLAUDE.md.

## Layer Rules

The dependency hierarchy is strictly enforced:
```
utils -> config -> models -> services -> providers -> screens/widgets
```

## Checks to Run

For each layer, grep for forbidden imports. Use relative import patterns since the codebase uses relative imports.

### 1. utils/ must not import any app code
```bash
grep -rn "import '.*\(config\|models\|services\|providers\|screens\|widgets\)/" lib/utils/
```

### 2. config/ must not import models, services, providers, screens, or widgets
```bash
grep -rn "import '.*\(models\|services\|providers\|screens\|widgets\)/" lib/config/
```

### 3. models/ must not import services, providers, screens, or widgets
```bash
grep -rn "import '.*\(services\|providers\|screens\|widgets\)/" lib/models/
```

### 4. services/ must not import providers, screens, or widgets
```bash
grep -rn "import '.*\(providers\|screens\|widgets\)/" lib/services/
```

### 5. providers/ must not import screens or widgets
```bash
grep -rn "import '.*\(screens\|widgets\)/" lib/providers/
```

### 6. widgets/ must not import screens
```bash
grep -rn "import '.*screens/" lib/widgets/
```

## Also Check

### Package imports where relative should be used
```bash
grep -rn "import 'package:habit_tracker/" lib/
```
These should be relative imports instead.

## Output Format

Report violations grouped by layer:
```
=== Layer Violations ===

utils/ (should import nothing from app):
  [CLEAN] No violations

models/ (should not import services/providers/screens/widgets):
  VIOLATION: lib/models/foo.dart:5 — imports from services/
  
...

=== Summary ===
Total violations: X
Layers clean: Y/6
```

If no violations found, report: "All 6 dependency layers are clean."
