# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-26

### Added
- **Clean Architecture Foundation**: Pure Dart Domain Layer (`CalculateAIPriceUseCase`, `UserEntity`, `ServiceItem`, `EscrowOrder`, `BarterContract`).
- **Hyperlocal Map Discovery**: Radius-aware campus interactive map for UIN Sunan Gunung Djati Bandung (Cibiru).
- **Escrow-Backed Orders**: State machine safeguarding payments with deposit, milestone submission, and dual-party completion release.
- **Bilateral Smart Barter**: Non-monetary peer-to-peer exchange of student skills with deliverable proof verification.
- **AI Price Estimator**: Cloud-powered LLM price recommendations (Groq Cloud LLM / 9router) with deterministic campus algorithmic fallback.
- **Role-Based Access Control (RBAC)**: Distinct permissions and viewports for Client (Student), Service Provider, and Campus Admin.
- **Academic Integrity Guardrails**: Strix-compliant anti-joki filtering prohibiting academic dishonesty.
- **DevOps CI/CD Automation**: GitHub Actions pipeline for linting, testing, coverage, and APK artifact builds.
