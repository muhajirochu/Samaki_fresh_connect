# AppLogger — Decision Record

**Status:** Accepted (2026-08-02)
**Context:** Samaki Fresh Connect cleanup, Wave 3.

## Decision

Keep `lib/utils/logger.dart` (the `AppLogger` wrapper around `package:logger`) as the project's logging standard.

## Context

`AppLogger` is the de facto logging standard across the codebase — 288 call sites in 30 files at the time of this decision. The wrapper exposes `debug`, `info`, `warning`, `error`, and `fatal` levels and silences output in release builds via `kDebugMode`.

Three alternatives were considered:

| Option | Pros | Cons |
|---|---|---|
| **`package:logger` (current)** | Already in use; well-tested; pretty console output. | Pulls in a transitive dep. |
| **`dart:developer` `log()`** | Zero deps; native; structured `name`/`error`/`level` support. | Loses pretty console output; 288 call sites to migrate. |
| **`package:logging`** | Standard Dart team package; plays well with `dart:developer`. | New dep; 288 call sites to migrate. |

## Rationale

The functional gain from any migration is marginal. We are not chasing logging-throughput, structured-log shipping, or integration with an observability backend. We use `AppLogger` to print human-readable lines during development and stay silent in release. The current setup already does both, with the bonus that `addTestListener` / `removeTestListener` hooks exist for the one test that captures log events (`test/features/buyers/buyer_map_sellers_runtime_report.dart`).

Migrating all 288 call sites would buy nothing functional and risk regressions. We keep the status quo and document the choice so future contributors do not re-litigate it.

## Consequences

- `AppLogger` stays the only logging API in `lib/`.
- New code that needs logging imports `package:.../utils/logger.dart` and calls `AppLogger.*` — never `dart:developer` or `print`.
- If a future project does need structured log shipping (e.g. Sentry, Cloud Logging), revisit Option B or C; the `AppLogger` wrapper is small enough to swap underneath without touching call sites.
