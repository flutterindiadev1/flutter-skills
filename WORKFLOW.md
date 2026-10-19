# Feature Implementation Runbook & Prompt Playbook

This runbook provides the exact, sequential prompt templates to pass to your AI assistant to build any Flutter feature from scratch without writing spaghetti code.

---

## 🔄 The 6-Stage Feature Development Pipeline

Follow these steps in strict sequence for any new feature:

```
[Phase 1: Architect] ➡️ [Phase 2: Data] ➡️ [Phase 3: BLoC] ➡️ [Phase 4: UI] ➡️ [Phase 5: QA/Tests] ➡️ [Phase 6: Reviewer]
```

---

### Phase 1: Lead Architect Prompt (`@flutter-architect`)

> **When to use**: Before any code is generated for a new feature.

```text
Act as @flutter-architect. We are implementing the [FEATURE_NAME] feature (e.g., OTP Verification, Product Catalog).
Here are the requirements:
[PASTE REQUIREMENTS / API SPEC / FIGMA OVERVIEW]

Please generate ONLY the architectural foundation:
1. File tree adhering to Feature-First Clean Architecture under lib/features/[FEATURE_NAME]/.
2. Pure Domain Entities with Equatable value equality under domain/entities/.
3. Abstract Repository contracts returning Either<Failure, T> under domain/repositories/.
4. Single-responsibility UseCases under domain/usecases/.
5. GetIt Dependency Injection registration template.

STRICT BOUNDARY: Do NOT generate presentation widgets or concrete network/Dio code.
```

---

### Phase 2: Data & Network Agent Prompt (`@flutter-data`)

> **When to use**: Once the Architect has defined entities and repository contracts.

```text
Act as @flutter-data. Using the abstract repository interfaces and entities from Phase 1, implement the data layer:
1. DTO Models extending/mapping to Domain Entities with fromJson/toJson and .toEntity() under data/models/.
2. Remote DataSource interface & implementation using Dio (handling DioException -> ServerException) under data/datasources/.
3. Concrete Repository implementation catching Exceptions and returning Either<Failure, T> under data/repositories/.

STRICT BOUNDARY: Do NOT import flutter/material.dart and do NOT write any widget code.
```

---

### Phase 3: Domain & State (BLoC) Agent Prompt (`@flutter-bloc`)

> **When to use**: Once UseCases and repository contracts exist.

```text
Act as @flutter-bloc. Implement the reactive state management for [FEATURE_NAME]:
1. Immutable States under presentation/bloc/[FEATURE]_state.dart with explicit status (initial, loading, success, failure) using Equatable.
2. User-intent driven Events under presentation/bloc/[FEATURE]_event.dart.
3. BLoC implementation orchestrating the UseCases under presentation/bloc/[FEATURE]_bloc.dart.
4. Apply bloc_concurrency transformers (droppable for buttons, restartable for search inputs).

STRICT BOUNDARY: Do NOT write UI layout code (Columns, Rows, Scaffolds) or direct network requests.
```

---

### Phase 4: UI/UX Design System Agent Prompt (`@flutter-ui`)

> **When to use**: Once the BLoC and states are finalized.

```text
Act as @flutter-ui. Implement the UI layer for [FEATURE_NAME] binding to [FEATURE]_bloc:
1. Enforce the 60-Line Widget Rule: Break the screen down into atomic sub-widgets under presentation/widgets/.
2. Page orchestrator under presentation/pages/ providing Scaffold, SafeArea, and SingleChildScrollView to prevent keyboard overflow.
3. Use BlocListener for side effects (navigation, Snackbars) and BlocBuilder strictly for rendering.
4. Strictly use Theme.of(context).colorScheme and textTheme (no hardcoded hex colors or text styles).
5. All static widgets must use const constructors.

STRICT BOUNDARY: Do NOT write business logic, direct API calls, or helper methods (_buildWidget).
```

---

### Phase 5: Test & QA Agent Prompt (`@flutter-qa`)

> **When to use**: Once feature code is generated.

```text
Act as @flutter-qa. Generate a comprehensive automated test suite for [FEATURE_NAME]:
1. Unit tests for UseCases with Mocktail mocks in test/features/[FEATURE_NAME]/domain/usecases/.
2. State transition tests using bloc_test covering initial, loading, success, and failure paths in test/features/[FEATURE_NAME]/presentation/bloc/.
3. Widget tests verifying UI rendering during loading, error, and loaded states in test/features/[FEATURE_NAME]/presentation/widgets/.

STRICT BOUNDARY: Ensure zero mock leakage and no flaky timers.
```

---

### Phase 6: Code Reviewer & Linter Agent Prompt (`@flutter-reviewer`)

> **When to use**: Before submitting code or merging.

```text
Act as @flutter-reviewer. Audit the newly generated code for [FEATURE_NAME] against RULES.md:
1. Check for unmounted BuildContext across async gaps (if (!context.mounted) return;).
2. Check for memory leaks (verify all TextEditingControllers, FocusNodes, and Streams are disposed).
3. Validate the 60-line widget rule (reject any build method > 80 lines).
4. Verify const constructor correctness and zero hardcoded colors.
5. Provide a line-by-line diff for any identified violations.
```
