# Contributing to SakuSkill Mobile

Thank you for your interest in contributing to SakuSkill Mobile! We welcome contributions to enhance student peer-to-peer productivity, ethical skill exchange, and clean architecture excellence.

---

## 📋 Git Workflow & Branching Strategy

We follow standard Trunk-Based and GitHub-Flow practices:

* `main` — Production-ready code. Protected branch.
* `feature/<feature-name>` — New capabilities or UI modules.
* `fix/<bug-description>` — Bug fixes and security patches.
* `refactor/<module-name>` — Architectural improvements without behavior changes.

---

## 📝 Commit Convention

We enforce the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification:

* `feat:` A new user-facing feature.
* `fix:` A bug fix.
* `docs:` Documentation only changes.
* `style:` Formatting, missing semi colons, no code changes.
* `refactor:` Code change that neither fixes a bug nor adds a feature.
* `test:` Adding missing tests or correcting existing tests.
* `ci:` Changes to CI/CD configuration files and scripts.
* `chore:` Build process or auxiliary tool changes.

**Example:**
```bash
feat(escrow): add bilateral confirmation before fund release
fix(map): resolve radius calculation under low GPS accuracy
test(security): add test cases for anti-joki keyword enforcement
```

---

## 🛠️ Development & Quality Checklist

Before opening a Pull Request:
1. Ensure all packages resolve cleanly: `flutter pub get`
2. Run static analysis without errors or warnings: `flutter analyze`
3. Execute all unit and widget tests: `flutter test`
4. Confirm no secrets (e.g. API tokens, credentials) are committed.
5. Verify Clean Architecture boundaries: Domain layer must not import Flutter or Presentation packages.
