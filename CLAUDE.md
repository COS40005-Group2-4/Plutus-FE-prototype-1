# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Plutus is a cross-platform personal finance management app built with Flutter (Dart SDK ^3.9.2). It targets Android, iOS, macOS, Linux, Windows, and Web. The app features double-entry bookkeeping, investment portfolio tracking (via a Go FFI backend), cloud backup to AWS S3, Google OAuth authentication, OCR receipt scanning, AI-powered transaction categorization, and multi-currency support.

## Common Commands

```bash
# Run the app (requires .env file — copy from .env.example)
flutter run --dart-define-from-file=.env

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Static analysis
flutter analyze

# Get dependencies
flutter pub get

# Regenerate mockito mocks after changing @GenerateMocks annotations
dart run build_runner build --delete-conflicting-outputs

# Build for web (CI uses this via amplify.yml)
flutter build web --release --no-tree-shake-icons --no-wasm

# Build Go FFI library (from Plutus-backend-prototype-2/)
# macOS: go build -o libplutus.dylib -buildmode=c-shared ./ffi.go
# Linux: go build -o libplutus.so -buildmode=c-shared ./ffi.go
# Android ARM64: GOARCH=arm64 go build -o libplutus.so -buildmode=c-shared ./ffi.go

# Build & deploy AI Lambda (from lambda/)
cd lambda && bash package.sh          # creates package.zip (~17MB, targets linux/x86_64)
cd terraform && terraform apply       # deploys Lambda + API Gateway

# Run Lambda tests
cd lambda && python -m pytest tests/
```

## Architecture

### State Management & DI
- **Provider** (ChangeNotifier) for UI state: `AuthProvider`, `BackupProvider`, `DashboardProvider`, `SettingsProvider`, `ProfileProvider`, `WidgetVisibilityProvider`
- **GetIt** for dependency injection with 3-tier registration in `lib/di/service_locator.dart`:
  - Tier 0: Leaf services (database, FFI, APIs, auth)
  - Tier 1: Composite services (user, profile, settings, transactions, investments, bills)
  - Tier 2: Orchestrators (SyncManager)

### Key Layers
- `lib/services/` — Business logic. Services use interfaces (`lib/services/interfaces/`) for testability. `backend_ffi_service.dart` bridges to the Go backend via FFI; platform-specific implementations in `backend_ffi_service_io.dart`.
- `lib/providers/` — ChangeNotifier classes consumed by the widget tree.
- `lib/models/` — Data models (transactions use double-entry posting, backups have versioning/conflict models).
- `lib/screens/` — Full-page UI widgets.
- `lib/widgets/` — Reusable UI components.
- `lib/config/` — AWS and OAuth configuration (reads from .env via flutter_dotenv).
- `lib/theme/` — Design tokens: `app_colors.dart` (light/dark), `app_radius.dart`, `app_spacing.dart`.
- `lib/l10n/` — Internationalization (English and Vietnamese).

### AI Categorization Pipeline
Hybrid offline-cloud system for auto-categorizing transactions into double-entry accounts.

**Flow** (`AICategoryPipeline`):
1. **Keyword matching** (free, instant) — `OCRService` maps known payees to accounts offline
2. **Cloud AI fallback** — if keyword returns "Other", calls AWS Lambda → Bedrock Claude Haiku 4.5
3. **Manual fallback** — "Expenses:Uncategorized" if both fail

**Key design decisions:**
- `suggestStream()` uses 500ms debounced streams for real-time UI updates in manual import
- `suggestBatch()` only sends keyword-unmatched rows to the cloud API (cost optimization)
- User corrections stored in SQLite `ai_corrections` table and sent to Lambda as few-shot examples
- `AIServiceOffline` is a no-op stub used when cloud is unavailable

**Lambda backend** (`lambda/`): Python 3.12 on AWS Lambda, invokes Bedrock via inference profile (`global.anthropic.claude-haiku-4-5-20251001-v1:0`). Three handlers:
- `categorize/handler.py` — transaction categorization (payee → account, returns confidence score)
- `insights/handler.py` — financial health scoring with locale-aware (EN/VI) narrative; includes Vietnam-specific context (Tết, gold prices, local banks)
- `report_insights/handler.py` — monthly report narrative generation

Shared code in `shared/` (Bedrock client, Pydantic models, prompt templates). Build with `package.sh` — must target `manylinux2014_x86_64` for native dependencies (pydantic-core).

**Terraform** (`terraform/ai_api_gateway.tf`, `terraform/ai_lambda.tf`): REST API Gateway at `/categorize` (POST) with CORS and throttling (10 req/sec, 20 burst). Lambda IAM requires both inference profile ARN and foundation model ARN for Bedrock access.

### Go FFI Backend
`Plutus-backend-prototype-2/` contains a Go library compiled to native shared libraries (`.dll`/`.so`/`.dylib`). It handles portfolio analysis and transaction processing. The FFI header is `libplutus.h`. For Android, copy the `.so` to `android/src/main/jniLibs/arm64-v8a/` after building.

**Platform-specific imports:** The FFI service uses conditional compilation — `backend_ffi_service.dart` is the stub/web fallback, `backend_ffi_service_io.dart` is the real implementation for mobile/desktop. This `_io.dart` / `_web.dart` pattern is used elsewhere for platform-specific code.

### Local Packages
`packages/dashboard/` is a local Flutter package (listed in pubspec.yaml as a path dependency) providing the customizable dashboard widget system used by `DashboardProvider`.

### Routing
Named routes defined in `lib/main.dart` using `MaterialApp.routes`. Navigation via `Navigator.pushReplacementNamed()`.

### Database
SQLite via sqflite (mobile/desktop) and sqflite_common_ffi (desktop fallback). Schema at version 6 with migrations in `database_service.dart`. The `ai_corrections` table stores user feedback on AI suggestions for few-shot learning.

### Testing
Tests in `test/` use mockito with auto-generated mocks. Mock declarations live in `test/helpers/mock_services.dart`; regenerate with `dart run build_runner build`. Test fixtures with factory functions in `test/helpers/test_fixtures.dart`.

### Infrastructure
- **AWS Amplify** for web CI/CD (`amplify.yml`)
- **Terraform** in `terraform/` for AWS resources (S3, DynamoDB, API Gateway, Lambda)
- **AWS S3** for cloud backup with versioning and conflict resolution
- **AWS DynamoDB** for T&C acceptance tracking
- **AWS Bedrock** (Claude Haiku 4.5) for AI categorization via Lambda + API Gateway (region: `ap-southeast-1`)

## Code Conventions (from .cursor/rules)

- **Do not modify** anything in `Plutus-backend-prototype-2/` unless explicitly asked.
- Design principle follows **AWS CloudWatch dashboard** style.
- Always declare types for variables, function parameters, and return values. Avoid `any`/`dynamic`.
- Use `const` constructors wherever possible to reduce rebuilds.
- Avoid deeply nested widget trees — break large widgets into smaller, focused, reusable components.
- Use `GetIt` singletons for services/repositories, lazy singletons for controllers, factories for use cases.
- Use `AppLocalizations` for all user-facing strings (English and Vietnamese).
- Service interfaces live in `lib/services/interfaces/` (prefix: `i_*.dart`) with a barrel file `interfaces.dart`.

## Environment Setup

Copy `.env.example` to `.env` and fill in:
- Google OAuth client IDs (web, Android, desktop) and secrets
- AWS credentials, region, S3 bucket name, DynamoDB table name
- API keys for CoinGecko, Alpha Vantage, Exchange Rate API
- `AI_API_GATEWAY_URL` and `AI_API_KEY` (from Terraform outputs after deploying `terraform/`)
