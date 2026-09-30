# mova

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Recurring subscriptions and accounts

MOVA stores subscriptions and their payment history in SQLite. Recording a
charge creates or links an expense transaction and advances the next charge
date; paused and cancelled subscriptions do not appear in upcoming charges.
Subscriptions can use an existing account or card; account associations are
optional. Local reminders use MOVA's notification preferences.

## Upcoming payments

The Upcoming Payments screen displays active subscription charges without
creating duplicate subscription records, alongside one-time, recurring, and
credit-card payments. Future obligations are not expense transactions. Paying
a regular obligation creates or links one expense and stores its history;
paying a credit card creates an account transfer to reduce the debt without
recording the card payment as a second expense. The account and payment
histories are included in SQLite backups.

## Receipt scanning

On Android and iOS, expenses can be created from a camera photo or gallery
image. On-device text recognition suggests the merchant, total, date, and
existing category; every value remains editable before the expense is saved.
The image, item details, and reference are linked to the single SQLite
transaction and included in data backups. A same-date, same-amount match is
shown before saving so the user can cancel or explicitly continue.

## Backups and restore

The Backups screen creates versioned JSON backup files in MOVA's app documents,
lets users save or share them with the operating system, and previews files
before restoring. Restore first creates a pre-restore backup, then replaces
financial records in a SQLite transaction while preserving login credentials
and session/security settings. The importer accepts the previous flat v1
backup format; passwords and security PINs are never exported. Receipt images
are embedded in the JSON payload so they can be restored with their movements.

Automatic backups support daily, weekly, or monthly cadence and configurable
retention. Mobile operating systems do not guarantee exact background
execution, so MOVA checks for due backups when the app starts or resumes rather
than promising work while the app is closed.

## Nivo local intelligence

Nivo's current data and intelligence layers run on-device and read MOVA's
existing SQLite records through `NivoRepository`. `NivoParser` uses local
Spanish keyword, category, account, goal, amount, and date matching;
`NivoEngine` calculates deterministic summaries and returns templated
`NivoResponse` values. Local actions for expenses, income, savings, goals, and
shopping lists call MOVA's existing `DatabaseHelper` operations; incomplete or
OCR-derived actions are proposed for confirmation, and possible expense
duplicates are checked against existing transactions. Destructive actions are
not enabled. No financial data is sent over the network or to external AI
services. The Nivo screen is available from the More section and can also review
an existing receipt draft from the transaction form.

Run the local Nivo and persistence tests with:

```sh
flutter test --no-pub test/nivo_actions_test.dart test/nivo_intelligence_test.dart test/nivo_repository_test.dart test/nivo_screen_test.dart
```
