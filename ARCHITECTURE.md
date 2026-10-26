# Clean Architecture & Engineering Design

SakuSkill Mobile is engineered in strict compliance with **Uncle Bob's Clean Architecture** principles, decoupling campus business rules from UI toolkits, networking libraries, and persistence layers.

---

## 🏛 Layered Architecture Structure

```
                  ┌────────────────────────────────────────┐
                  │           Presentation Layer           │
                  │   Pages, Widgets, Providers / Cubit    │
                  └───────────────────┬────────────────────┘
                                      │ (depends on)
                                      ▼
                  ┌────────────────────────────────────────┐
                  │              Domain Layer              │
                  │  Entities, Value Objects, Use Cases    │
                  │         (100% Pure Dart SDK)           │
                  └───────────────────▲────────────────────┘
                                      │ (implements)
                  ┌───────────────────┴────────────────────┐
                  │               Data Layer               │
                  │   Models, Repositories, Data Sources   │
                  │     (Local State / Remote Groq LLM)    │
                  └────────────────────────────────────────┘
```

### 1. Domain Layer (`lib/features/*/domain/`)
- **Entities**: Business models representing campus entities (`UserEntity`, `ServiceItem`, `EscrowOrder`, `BarterContract`).
- **Use Cases**: Pure Dart business logic without any dependency on Flutter SDK. For example, `CalculateAIPriceUseCase` calculates deterministic price bounds based on hours, complexity multiplier, and campus baseline rates.
- **Repository Contracts**: Abstract interfaces dictating data operations.

### 2. Presentation Layer (`lib/features/*/presentation/`)
- **Pages**: Screen views (`HomeDiscoveryPage`, `EscrowOrdersPage`, `BarterHubPage`, `AuthPage`).
- **Widgets**: Reusable atomic UI components (`ServiceCard`, `AIEstimatorSheet`, `CampusMapCard`, `CategoryChipsBar`).
- **State Management**: Reactive state management via `Provider` / `ChangeNotifier` (`AppStateProvider`).

### 3. Data Layer (`lib/features/*/data/`)
- **Data Sources**:
  - `NineRouterAIService`: Integrates with Groq Cloud LLM (`openai/gpt-oss-120b`) via REST API, with fallback to deterministic local campus algorithmic heuristics.
  - In-memory mock repositories and state caches.

---

## 🛡 Security Guardrails (Strix Standards)

- **`UrlSanitizer`**: Enforces strict URL scheme validation (`http://`, `https://`) and blocks academic cheating keywords ("joki tugas", "joki skripsi", "buatkan makalah").
- **`RBACMatrix`**: Evaluates permission matrix between `UserRole.student`, `UserRole.provider`, and `UserRole.admin`.
- **`EscrowOrder` State Machine**:
  `Created` ➔ `Funded` ➔ `InProgress` ➔ `Submitted` ➔ `Completed` (or `Disputed`).
