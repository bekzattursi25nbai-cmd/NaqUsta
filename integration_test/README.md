# Integration Tests (Critical Flows)

This suite uses Firebase Emulator Suite for deterministic auth/firestore/storage behavior.

## Prerequisites

1. Firebase CLI installed (`firebase --version`)
2. Flutter dependencies installed (`flutter pub get`)
3. Android emulator or iOS simulator running

## Start emulators

```bash
firebase emulators:start --project naqusta --only auth,firestore,storage
```

## Run critical flow integration tests

Android emulator example:

```bash
flutter test integration_test/critical_flow_test.dart -d emulator-5554
```

iOS simulator example:

```bash
flutter test integration_test/critical_flow_test.dart -d ios
```

## One-command CI-friendly run (local/CI shell)

```bash
firebase emulators:exec --project naqusta --only auth,firestore,storage \
  "flutter test integration_test/critical_flow_test.dart -d emulator-5554"
```

## What is covered

1. Client creates order and Firestore document is persisted
2. Worker can read OPEN feed and order details
3. Worker sends offer and client can read offers list
4. Client accepts worker: order -> IN_PROGRESS, chat created, order removed from OPEN feed
5. Worker marks done and client confirms -> COMPLETED
6. Client submits review and review document exists

## Notes

- Tests reset Auth and Firestore emulator state before each test case.
- Storage emulator is connected for parity, though these critical tests do not upload files.
