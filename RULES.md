# Flutter Vibe Coding Manifesto & Anti-Spaghetti Rules

This document outlines the non-negotiable architectural, coding, and quality rules for developing Flutter applications when "vibe coding" (rapid, AI-assisted development). Its objective is to prevent spaghetti code, maintain high velocity, avoid regressions, and ensure code remains scalable, maintainable, and testable.

---

## 1. The Core Architectural Philosophy

### 1.1. Feature-First Clean Architecture
Never organize files by technical type across the entire project (e.g., global `/models`, `/views`, `/controllers`). Always organize by **Feature**, subdivided into **Clean Architecture** layers:

```
lib/
├── core/                        # Cross-cutting utilities & infrastructure
│   ├── constants/               # Global strings, assets, dimensions
│   ├── errors/                  # App failures, exceptions, error mapper
│   ├── network/                 # Dio client, interceptors, network info
│   ├── theme/                   # ColorScheme, TextTheme, AppTheme
│   ├── utils/                   # Extensions, formatters, validators
│   └── di/                      # Dependency injection (get_it / injectable)
└── features/
    └── [feature_name]/
        ├── data/                # Data sources, DTO models, repository impls
        ├── domain/              # Entities, repository interfaces, use cases
        └── presentation/        # BLoCs/Cubits, pages, feature widgets
```

### 1.2. Strict Layer Inversion Rules
1. **Domain Layer is Sovereign & Pure**:
   - `domain/` must contain **ZERO** UI or platform dependencies. No `flutter/material.dart`, no `dio`, no SQLite/Hive.
   - Contains: Entities, Repository Contracts (`abstract class`), and UseCases.
2. **Data Layer Implements Domain**:
   - `data/` implements repository interfaces defined in `domain/`.
   - Data sources throw `Exception`s (e.g., `ServerException`, `CacheException`).
   - Repositories catch `Exception`s and return `Either<Failure, T>` (using `fpdart` or `dartz`).
3. **Presentation Layer Consumes Domain**:
   - `presentation/` only communicates with `domain/` via UseCases or BLoC/Cubit.
   - It never directly references `data/` classes (e.g., no raw DTO models or network clients in widgets).

---

## 2. Widget Hygiene & Presentation Guardrails

### 2.1. The 60-Line Rule & Atomic Breakdown
- **No God-Widgets**: A single widget’s `build()` method must never exceed **60–80 lines**.
- **No Helper Methods for UI**:
  ```dart
  // ❌ ANTI-PATTERN: Rebuilds entire widget; kills Flutter element caching
  Widget _buildUserProfile() {
    return Column(children: [...]);
  }

  // ✅ CORRECT: Extract to a separate StatelessWidget
  class UserProfileSection extends StatelessWidget {
    const UserProfileSection({super.key});
    @override
    Widget build(BuildContext context) { ... }
  }
  ```
- Any sub-tree deeper than 4 levels or with distinct semantic meaning must be extracted into a dedicated widget in `presentation/widgets/`.

### 2.2. Zero Business Logic in the UI
- Widgets are strictly **visual renderers** and **event dispatchers**.
- ❌ **Forbidden**:
  - Direct HTTP calls, Dio requests, or database queries inside `onPressed` or `initState`.
  - Complex mathematical calculations or date formatting logic inside `build()`.
  - Manipulating raw state collections inside widgets.
- ✅ **Required**:
  - Dispatch an event to BLoC or trigger a Cubit method.
  - Perform formatting in use cases, view models, or pure utility extension methods.

### 2.3. Asynchronous Context Gap Safety
Never use `BuildContext` across an asynchronous boundary without an immediate `context.mounted` check.

```dart
// ❌ DANGEROUS: Crashes if widget unmounts during network call
await context.read<AuthCubit>().login(email, password);
Navigator.of(context).pushNamed(AppRoutes.dashboard);

// ✅ SAFE
await context.read<AuthCubit>().login(email, password);
if (!context.mounted) return;
Navigator.of(context).pushNamed(AppRoutes.dashboard);
```

### 2.4. Separation of Builders vs. Listeners
- **`BlocBuilder`**: Purely for rendering UI based on state changes. Must be idempotent and free of side effects.
  - **NEVER** trigger navigation, show Snackbars, or open dialogs inside `builder`.
- **`BlocListener`**: Purely for one-off side effects (Navigation, Dialogs, Toasts, Analytics).
- Use `BlocConsumer` when both rebuilding UI and executing a side effect are needed for the same state.

---

## 3. State Management & Immutability Rules

### 3.1. Immutability by Default
- All States and Events must extend `Equatable` or be generated via `@freezed`.
- Never mutate collections in-place:
  ```dart
  // ❌ MUTATION BUG: Will not trigger widget rebuild because state reference hasn't changed
  state.cartItems.add(newItem);
  emit(state);

  // ✅ CORRECT: Emit fresh immutable copy
  emit(state.copyWith(cartItems: [...state.cartItems, newItem]));
  ```

### 3.2. State Exhaustiveness
Always design states with exhaustive lifecycle phases:
1. `Initial`
2. `Loading` (with optional previous data for pull-to-refresh)
3. `Success<T>` (holds strongly-typed domain entities)
4. `Failure` (holds error message, error code, and retry capability)

### 3.3. Event Concurrency & Debouncing
For user inputs that can fire rapidly (search field inputs, form field keystrokes, rapid button taps):
- Use `bloc_concurrency` transformers.
- Apply `restartable()` or `debounceTime()` for search events.
- Apply `droppable()` for form submission buttons to prevent multiple simultaneous API hits.

---

## 4. UI/UX Resiliency & Responsive Engineering

### 4.1. Keyboard & View Inset Management
- Always wrap scrollable input screens (forms, authentication, checkouts) with `SafeArea` and `SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag)`.
- Never allow `A RenderFlex overflowed by ... pixels` when the soft keyboard appears.

### 4.2. Accessibility (a11y) & Dynamic Text Scaling
- Test with large text scale factors.
- Avoid wrapping text in fixed height/width containers without handling text overflow (`TextOverflow.ellipsis`, `Expanded`, or `FittedBox`).
- Wrap custom interactive widgets in `Semantics(button: true, label: '...', child: ...)`.

### 4.3. Strict Theme Conformance
- Never hardcode color hex values (`Color(0xFF1E88E5)`) or raw text styles directly in widgets.
- Always use `Theme.of(context).colorScheme.[colorName]` and `Theme.of(context).textTheme.[textStyle]`.
- This ensures full support for Light Mode, Dark Mode, and dynamic theme switching.

---

## 5. Performance & Memory Management

### 5.1. The `const` Constructor Imperative
- Prefix every constructor with `const` wherever possible.
- Prevents unnecessary widget repainting and saves memory during tree diffing.

### 5.2. Mandatory Resource Disposal
Every resource created inside a `StatefulWidget` must be explicitly cleaned up inside `dispose()`:
```dart
@override
void dispose() {
  _textController.dispose();
  _focusNode.dispose();
  _scrollController.dispose();
  _animationController.dispose();
  _streamSubscription.cancel();
  super.dispose();
}
```

### 5.3. List & Scroll Performance
- **NEVER** construct lists using `Column(children: items.map(...))` or `ListView(children: ...)` for dynamic or large datasets.
- Always use `ListView.builder` or `ListView.separated` with `itemExtent` or `prototypeItem` for constant-time layout measurement.

### 5.4. Offloading Heavy Computation
- Never parse massive JSON payloads (e.g., > 1 MB) or run heavy cryptographic/image processing on the main UI isolate.
- Use `compute()` or `Isolate.run()` to offload CPU-intensive tasks.

---

## 6. Dependency Injection & Testability Contracts

### 6.1. Inversion of Control (IoC)
- No class should directly instantiate its dependencies (`new ApiClient()` or `AuthRepositoryImpl()`).
- All dependencies must be injected via constructors and registered in `core/di/injection.dart` using `GetIt` or `injectable`.

### 6.2. Mandatory Test Coverage Targets
For any feature generated during vibe coding:
1. **UseCases**: 100% unit test coverage using `mocktail` mocks.
2. **BLoCs/Cubits**: State transition test coverage for every event using `bloc_test`.
3. **Repositories**: Test both successful remote data responses and error/offline fallbacks.

---

## 7. Vibe Coding Anti-Pattern Checklist (Self-Audit)

Before accepting any code generated by an AI assistant, verify:

| Violation | Status | Fix |
| :--- | :--- | :--- |
| `build()` method > 80 lines | ❌ Reject | Split into modular `StatelessWidget` classes in `widgets/` |
| `http` / `dio` call inside widget | ❌ Reject | Move to datasource $\rightarrow$ repo $\rightarrow$ use case $\rightarrow$ BLoC |
| Unmounted context after `await` | ❌ Reject | Add `if (!context.mounted) return;` |
| Hardcoded colors or styles | ❌ Reject | Replace with `Theme.of(context)` references |
| Controllers not disposed | ❌ Reject | Add explicit `.dispose()` inside `dispose()` method |
| Direct state mutation (`items.add()`) | ❌ Reject | Use immutable `copyWith` with cloned list |
| Helper methods rendering UI (`_build...`) | ❌ Reject | Convert helper method to a standalone `StatelessWidget` |
| Missing `const` on static subtrees | ❌ Reject | Add `const` keywords |
